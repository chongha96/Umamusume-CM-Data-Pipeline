# Imports and Settings
import polars as pl
import polars.selectors as cs
from pathlib import Path
import re
import torch
from transformers import pipeline

_classifier_cache = None

DAYS = {
    1: "Day 1",
    2: "Day 2",
    3: "Day 3",
    4: "Day 4",
    5: "Finals"
}
#Creating candidate labels and template for Hugging Face ML Operation
labels_player_category = [
    "Competitive (minmax, strategic)",
    "For Fun (Oshi Player, Only Plays Favorite))",
    "Casual (Busy, not much time)",
    "Burnt out (Rarely play, log in time to time)"
]
hypothesis_player_category = "This person's current playstyle is {}"

labels_device_category = [
    "Mobile (Android/iOS/SteamOS)",
    "Desktop (Windows/Linux)"
]
hypothesis_device_category = "This person's  device is {}"


#Regex terms for cleaning uma roles (Free-form response)
ace_regex = r"(?i)pdm|ace|oshi|hybrid|gamble"
support_regex = (r"(?i)debuff|sac|throwaway|block|"
                 r"anti-runaway|struggle|proc|parent|dom|"
                 r"gaze|murmur|push|fill|help|kill|support|"
                 r"puller|chariot")

#Main cleaning function referenced by clean_cm.py module
#Input: Desired CM #
#Output: List of PL DataFrames containing data for each day of a CM (Day 1 - 5)
def clean_cm(cm_num: int) -> list[pl.DataFrame]:
    cm_days = _select_cols(_import_csv(cm_num))

    if not isinstance(cm_days, list):
        cm_days = [cm_days]

    cleaned_cm_days = []
    for cm_day in cm_days:
        cleaned = (
            cm_day.pipe(_categorize_uma_role)
            .pipe(_remove_parenthesis, "League")
            .pipe(_remove_parenthesis, "Weekly Career Count")
            .pipe(_clean_column_names)
            .pipe(_fill_missing_values, "player_type")
            .pipe(_batch_classify,labels_player_category,hypothesis_player_category,"player_type")
            .pipe(_fill_missing_values,"device")
            .pipe(_batch_classify,labels_device_category,hypothesis_device_category,"device")
            .unique()
        )
        cleaned_cm_days.append(cleaned)
    _write_to_cleaned_folder(cleaned_cm_days, cm_num)

    return cleaned_cm_days

# Select relevant columns for each day (Day 1-4, Finals)
def _select_cols(cm: pl.DataFrame) -> list[pl.DataFrame]:
    #Select statement that chooses the columns that will be used
    cm = cm.select(
        pl.coalesce(cs.by_name("Player IGN", "Unique display name", require_all=False), pl.lit(None)).alias("Player IGN"),
        cs.by_name("League Selection", require_all=False).name.map(lambda _: "League"),
        cs.by_name("Select day", require_all=False).name.map(lambda _: "Day"),
        cs.by_name("Roughly how much have you spent on the game so far? (EUR/USD)", require_all=False).name.map(lambda _: "Spend"),
        pl.coalesce(cs.matches("(?i)identify"), pl.lit(None)).alias("Player Type"),
        cs.matches("(?i)group"),
        cs.matches("(?i)career|(?i)borrow"),
        cs.contains("Day ", "Finals") - cs.matches("(?i)career|(?i)borrow"),
        pl.coalesce(cs.matches(r"(?i)Optional - Device|Operating system"), pl.lit(None).cast(pl.String)
        ).alias("Device")
    )

    #Now that rows are selected, break the data into separate days due to wide structure of survey
    #ie. Day 1 has a column for each uma, Day 2 has a column for each uma, etc.
    cm_days = []
    for i in range(len(DAYS)):
        day = DAYS[i + 1]
        #Check if CM has data for this day. If not, iterate to next day
        if cm.select(cs.contains(day)).width == 0:
            continue
        #"Anchor" column to see if there is data submitted for this day
        day_col = f"{day} - Team Comp - Uma 1 - Name" if day == "Finals" else f"{day} - Team Comp 1 - Uma 1 - Name"

        cm_day = (
            # Checks if uma 1 exists for the specific day. if not, discards the row.
            cm.filter(pl.col(day_col).str.strip_chars() != "")
            .select(
                #Adds all data relevant to the day
                (cs.all() - cs.contains("Day ", "Finals")),
                cs.contains(day)
            )
        )
        cm_days.append(cm_day)
    return cm_days

# Reads CSV file of Champions Meet and places into Polars DF
def _import_csv(cm_num: int) -> pl.DataFrame:
    this_file = Path(__file__).resolve()
    project_root = this_file.parents[2]
    file_path = project_root / "data" / "raw" / f"cm{cm_num}_finals.csv"
    return pl.read_csv(file_path, ignore_errors=True)

# Converts free-form Uma role responses into one of three buckets: Ace, Support, or None
def _categorize_uma_role(cm: pl.DataFrame) -> pl.DataFrame:
    role_cols = [c for c in cm.columns if c.endswith("Role")]

    return cm.with_columns([
        pl.when(pl.col(c).str.contains(ace_regex))
        .then(pl.lit("Ace"))
        .when(pl.col(c).str.contains(support_regex))
        .then(pl.lit("Support"))
        .otherwise(pl.lit(None))
        .alias(c)
        for c in role_cols
    ])

#Fill columns with missing values in order for Hugging Face model to work properly
def _fill_missing_values(cm: pl.DataFrame, col: str) -> pl.DataFrame:
    if col not in cm.columns:
        return cm

    return cm.with_columns(
        pl.col(col)
        .fill_null("Unknown")
        .str.strip_chars()
        .replace("", "Unknown")
        .alias(col)
    )


# Removes parenthesis from categorized responses that were used to guide user response
# ie. Graded (Unrestricted) -> Graded
def _remove_parenthesis(cm: pl.DataFrame, col: str) -> pl.DataFrame:
    if col not in cm.columns:
        return cm
    return cm.with_columns(
        pl.col(col)
        .str.replace(r"\s*\(.*\)", "")
        .str.strip_chars()
        .alias(col)
    )

# Cleaning column names to accurately format for BQ
def _clean_column_names(df: pl.DataFrame) -> pl.DataFrame:
    return df.rename({col: _sanitize(col) for col in df.columns})


def _sanitize(name: str) -> str:
    # Replaces any non-alphanumerical characters with _ (including space)
    name = re.sub(r'[^a-zA-Z0-9]+', '_', name)
    #Returns lower cased
    return name.strip('_').lower()


# Creates classifier for zero-shot classification based on bart-large-mnli
def _get_classifier():
    #Assigning classifier_cache to avoid load times for each CM
    global _classifier_cache
    if _classifier_cache is None:
        #Runs on CPU if no GPU is detected
        device_type = 0 if torch.cuda.is_available() else -1
        print(f"Loading model on {'GPU' if device_type == 0 else 'CPU'}...")
        _classifier_cache = pipeline(
            "zero-shot-classification",
            model="MoritzLaurer/ModernBERT-large-zeroshot-v2.0",
            device=device_type
        )
    return _classifier_cache


# Classifying player_type based on candidates
def _batch_classify(cm: pl.DataFrame, candidate_labels: list, hypothesis_template: str, col_name: str) -> pl.DataFrame:
    if col_name not in cm.columns or cm[col_name].null_count() == len(cm):
        return cm

    classifier = _get_classifier()

    col_select = cm[col_name].fill_null("").to_list()

    classify_types = classifier(
        col_select,
        candidate_labels=candidate_labels,
        hypothesis_template=hypothesis_template,
        batch_size=16,
        multi_label = True
    )
    classified_types = [result['labels'][0] for result in classify_types]
    return cm.with_columns(pl.Series(col_name, classified_types))


# File to write cleaned cm data to data/processed folder
def _write_to_cleaned_folder(cm: list[pl.DataFrame], cm_num: int):
    module_path = Path(__file__).resolve()
    project_root = module_path.parents[2]
    output_dir = project_root / "data" / "processed"
    output_dir.mkdir(parents=True, exist_ok=True)

    for i, cm_round in enumerate(cm):
        filename = f"cm{cm_num}_cleaned_day_{i + 1}.csv"
        filepath = output_dir / filename
        cm_round.write_csv(filepath)
        print(f"Exported {filename}: ({cm_round.height} rows, {cm_round.width} columns)")
