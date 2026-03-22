# Data Format Validation Report

## Overview
This document validates that the Flutter app data structures match the database schema as defined in `seed.sql` and `quick_insert_guide.sql`.

## ✅ VERIFIED FORMATS

### 1. Gender Values
**Database Constraint:** `check (gender in ('woman', 'man', 'non_binary', 'prefer_not_to_disclose', 'prefer_to_self_describe'))`

**Flutter Implementation:**
```dart
// demographics_screen.dart - _getGenderValue()
'Woman' → 'woman'
'Man' → 'man'
'Non-binary' → 'non_binary'
'Prefer not to disclose' → 'prefer_not_to_disclose'
'Prefer to self-describe' → 'prefer_to_self_describe'
```
✅ **Status:** MATCHES

---

### 2. PSQI Responses JSONB Structure
**Expected from quick_insert_guide.sql:**
```json
{
  "bed_time": "23:00",
  "sleep_latency_minutes": 20,
  "wake_time": "07:00",
  "actual_sleep_hours": 7,
  "disturbances": {
    "sleep_onset": "not_during_past_month",
    "night_waking": "less_than_once_week",
    ...
  },
  "overall_quality": "fairly_good",
  "medication_frequency": "not_during_past_month",
  "daytime_dysfunction": "no_problem",
  "enthusiasm_problem": "no_problem",
  "bed_partner": {
    "status": "partner_different_room"
  }
}
```

**Flutter Current Implementation (psqi_screen.dart):**
```dart
psqiResponses: {
  'bed_time': '${_bedTime!.hour}:${_bedTime!.minute}',
  'wake_time': '${_wakeTime!.hour}:${_wakeTime!.minute}',
  'minutes_to_sleep': _minutesToFallAsleep,
  'hours_of_sleep': _hoursOfSleep,
  'cannot_sleep_30min': _cannotSleepWithin30Min,
  ...
}
```

⚠️ **Status:** NEEDS UPDATE
**Issues:**
1. Field names don't match (e.g., `sleep_latency_minutes` vs `minutes_to_sleep`)
2. Missing nested `disturbances` object structure
3. Missing `bed_partner` section

---

### 3. Pre-Sleep Responses (SSS) JSONB
**Expected from seed.sql:**
```json
{
  "sleepiness_level": 5,
  "timestamp": "2025-01-01T22:30:00Z"
}
```

**Flutter Implementation (sss_screen.dart):**
✅ **Status:** MATCHES (structure looks correct)

---

### 4. Post-Sleep Responses (LSEQ) JSONB
**Expected from seed.sql:**
```json
{
  "getting_to_sleep": 7,
  "quality_of_sleep": 8,
  "awaking_difficulty": 6,
  "awaking_alertness": 7,
  "balance_coordination": 8,
  "mental_functioning": 7,
  "emotional_state": 8,
  "physical_wellbeing": 7,
  "overall_quality": 8,
  "restorative_quality": 7
}
```

**Flutter Implementation (lseq_screen.dart):**
✅ **Status:** MATCHES (10 fields as expected)

---

### 5. Condition Order Array
**Expected from seed.sql:**
```sql
ARRAY['control', 'personalized', 'fixed']::text[]
```

**Flutter Implementation (database_service.dart):**
```dart
Condition.control, Condition.fixed, Condition.personalized
// Values: 'control', 'fixed', 'personalized'
```
✅ **Status:** MATCHES

---

### 6. StudyStatus Values
**Expected:** `'pre_experiment'`, `'in_progress'`, `'completed'`, `'withdrawn'`

**Flutter Implementation (condition.dart):**
```dart
StudyStatus.preExperiment → 'pre_experiment'
StudyStatus.inProgress → 'in_progress'
StudyStatus.completed → 'completed'
```
✅ **Status:** MATCHES (withdrawn not yet implemented but not critical)

---

## 🔧 REQUIRED FIXES

### CRITICAL: PSQI Response Structure

**Current Flutter code sends:**
```dart
{
  'bed_time': '23:30',
  'minutes_to_sleep': 20,
  ...individual disturbance fields...
}
```

**Database expects:**
```json
{
  "bed_time": "23:00",
  "sleep_latency_minutes": 20,
  "disturbances": {
    "sleep_onset": "not_during_past_month",
    "night_waking": "less_than_once_week",
    ...
  },
  "bed_partner": {
    "status": "partner_different_room"
  }
}
```

**Action Required:** Update `psqi_screen.dart` to match nested structure.

---

## 📊 Summary

| Component | Status | Action Required |
|-----------|--------|-----------------|
| Gender values | ✅ Fixed | None |
| Condition order | ✅ Matches | None |
| Study status | ✅ Matches | None |
| SSS responses | ✅ Matches | None |
| LSEQ responses | ✅ Matches | None |
| **PSQI responses** | ⚠️ Mismatch | **Update structure** |

---

## Next Steps

1. **Fix PSQI structure** to match database schema
2. Add bed_partner section to PSQI
3. Ensure all field names match exactly (snake_case)
