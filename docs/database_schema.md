# Database Schema Documentation

## Overview
This document outlines the complete database schema for the Lullora Sleep Study application, matching the official Supabase specification.

## Tables

### 1. study_participants
Tracks users enrolled in the 3-night sleep study.

**Constraints:**
- `condition_order` must have exactly 3 elements
- `current_night` must be between 1-3
- `status` values: `pre_experiment`, `in_progress`, `completed`, `withdrawn`
- One participant per user (unique constraint)

### 2. pre_experiment_responses
Stores pre-experiment questionnaire responses.

**Constraints:**
- Gender values: `woman`, `man`, `non_binary`, `prefer_not_to_disclose`, `prefer_to_self_describe`
- Unique per participant

### 3. nightly_sessions
Records data for each of the 3 nights.

**Constraints:**
- `night_number` must be between 1-3
- `condition` values: `control`, `fixed`, `personalized`
- Unique per (participant_id, night_number)

### 4. post_experiment_responses
Stores post-experiment questionnaire responses.

**Constraints:**
- Unique per participant

## Key Updates Made

1. **Gender Field Normalization**: Changed from capitalized (Woman, Man) to lowercase with underscores
2. **Constraint Validation**: Added proper checks before database calls
3. **JSONB Structure**: Ensured all questionnaire responses use proper JSONB format
4. **Error Handling**: Improved validation messages to match constraints

## RLS Policies
All tables have Row Level Security enabled - users can only access their own data via `auth.uid()`.
