# Qualtrics Pre-Screening Survey Setup

## Step 1: Create New Survey

1. Log into Qualtrics → **Create a new project** → **Survey**
2. Name it: "Lullora Sleep Study Pre-Screening"

---

## Step 2: Add Study Information (Block 1)

1. Click **+ Add Block** → Name it "Study Information"
2. Add a **Text/Graphic** question
3. Paste your study description

---

## Step 3: Add Eligibility Questions (Block 2)

1. Click **+ Add Block** → Name it "Eligibility Screening"

### Question 1: English Fluency

- Question Type: **Multiple Choice**
- Text: "Are you fluent in English?"
- Choices: Yes, No

### Question 2: Age

- Question Type: **Text Entry** → Single Line
- Text: "What is your age?"
- Click **gear icon** → **Add Validation**:
  - Check **Content Validation**
  - Select **Number**
  - Set Min: 0, Max: 120

### Question 3: Hearing

- Question Type: **Multiple Choice**
- Text: "Do you have normal or corrected-to-normal hearing?"
- Choices: Yes, No

---

## Step 4: Add Contact Details (Block 3)

1. Click **+ Add Block** → Name it "Contact Details"

### Question 4: Name

- Question Type: **Text Entry**
- Text: "Please enter your full name"

### Question 5: Email

- Question Type: **Text Entry**
- Text: "Please enter your email address"
- Add Validation: **Content Type → Email Address**

---

## Step 5: Add Consent Form Block (Block 4)

1. Click **+ Add Block** → Name it "Informed Consent"

### Question 6: Download Consent Form

- Question Type: **Text/Graphic**
- Text:

```
Please download the Informed Consent Form below, read it carefully, sign it,
and upload the signed copy in the next question.

[Download Informed Consent Form](YOUR_CONSENT_FORM_URL)
```

- To add the link: Click **Rich Content Editor** → highlight text → click **Insert Link** → paste your PDF URL

### Question 7: Upload Signed Consent

- Question Type: **File Upload**
- Text: "Please upload your signed Informed Consent Form (PDF, JPG, or PNG)"
- Settings:
  - Click **gear icon** → **Add Validation** → **Force Response** (make it required)
  - File types: PDF, JPG, PNG
  - Max file size: 10 MB

---

## Step 6: Set Up Display Logic

### Make Block 3 & 4 conditional:

1. Click on **Block 3 (Contact Details)**
2. Click the **gear icon** → **Add Display Logic**
3. Set conditions:

   - Q1 (English) **Is Selected** → Yes
   - **AND** Q2 (Age) **Is Greater Than or Equal To** → 18
   - **AND** Q2 (Age) **Is Less Than or Equal To** → 99
   - **AND** Q3 (Hearing) **Is Selected** → Yes

4. **Repeat the same Display Logic for Block 4 (Informed Consent)**

---

## Step 7: Set Up Survey Flow with Branch Logic

Use **Survey Flow** to route ineligible participants to an end message.

### 7.1: Open Survey Flow

1. Click **Survey Flow** in the top navigation bar

### 7.2: Add Branch for Ineligible Participants

1. Click **Add Below** → **Branch**
2. Set condition: **If Q1 (English) = No**
3. Under that branch, click **Add Below** → **End of Survey**
4. Click **Customize** on the End of Survey element
5. Enter message: "Thank you for your interest. Unfortunately, you do not meet the eligibility criteria for this study."

### 7.3: Add More Ineligibility Branches

Repeat for other ineligibility conditions:

- **Q3 (Hearing) = No** → End of Survey (Ineligible)
- **Q2 (Age) < 18 OR > 99** → End of Survey (Ineligible)

### 7.4: Add Eligible End Message

1. At the bottom of Survey Flow, click **Customize** on the default End of Survey
2. Enter message: "Thank you! You are eligible to participate. We will contact you shortly with your login credentials and next steps."

> **Note**: If you can't find "End of Survey" in Survey Options, use Survey Flow instead. The UI varies by Qualtrics version.

---

## Step 8: Test & Publish

1. Click **Preview** to test all paths
2. Click **Publish** when ready
3. Share the anonymous link with potential participants

---

## Step 9: Export Responses

When you have responses:

1. Go to **Data & Analysis**
2. Click **Export & Import** → **Export Data**
3. Choose CSV format
4. **Important**: File uploads are stored separately - click on each response to download uploaded consent forms
5. Use CSV with the user creation script (see `tool/create_study_users.js`)

---

## Step 10: Access Uploaded Files

To download signed consent forms:

1. Go to **Data & Analysis**
2. Click on individual response row
3. Find the File Upload question → click **Download**
4. Or use **Export Data** → **Include file upload** option (Premium feature)

---

## Step 11: Set Up Automatic User Creation (Webhook)

This will automatically create a Supabase user and send credentials when someone completes the survey.

### 11.1: Deploy the Edge Function

First, deploy the Supabase Edge Function:

```bash
cd /path/to/lullora-sleep-hypnosis-app

# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Set secrets (replace with your values)
supabase secrets set RESEND_API_KEY=re_xxxxx
supabase secrets set FROM_EMAIL=noreply@yourdomain.com
supabase secrets set CONSENT_FORM_URL=https://your-domain.com/consent.pdf
supabase secrets set APP_DOWNLOAD_URL=https://testflight.apple.com/your-app

# Deploy the function (allow public access for webhook)
supabase functions deploy create-study-user --no-verify-jwt
```

Your webhook URL will be:

```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/create-study-user
```

### 11.2: Configure Qualtrics Workflow

1. In Qualtrics, go to **Workflows** → **Create a workflow**
2. Select **Started when an event is received** → **Survey response**
3. Choose event: **A survey response is created**
4. Click **+** → **Add a task** → **Web Service**

### 11.3: Configure the Web Service Task

1. **URL**: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/create-study-user`
2. **Method**: POST
3. **Headers**:
   - `Content-Type`: `application/json`
   - `Authorization`: `Bearer YOUR_SUPABASE_ANON_KEY`
4. **Body** (JSON):

```json
{
  "name": "${q://QID4/ChoiceTextEntryValue}",
  "email": "${q://QID5/ChoiceTextEntryValue}",
  "Q1": "${q://QID1/ChoiceGroup/SelectedChoices}",
  "Q3": "${q://QID3/ChoiceGroup/SelectedChoices}",
  "responseId": "${e://Field/ResponseID}"
}
```

> **Note**: Replace `QID4`, `QID5`, etc. with your actual question IDs. Find them in Survey Builder by clicking the question and looking at the ID in the URL or question settings.

### 11.4: Add Condition (Optional)

Only trigger for eligible participants:

1. Click **+ Add condition**
2. **Question** → Q1 (English) → **Is** → Yes
3. **AND** Q2 (Age) → **Is between** → 18 and 99
4. **AND** Q3 (Hearing) → **Is** → Yes

### 11.5: Save & Enable

1. Click **Save**
2. Toggle the workflow **ON**
3. Test by completing the survey yourself!

---

## Troubleshooting

### Check Edge Function Logs

```bash
supabase functions logs create-study-user
```

### Test Webhook Manually

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/create-study-user \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"name": "Test User", "email": "test@example.com", "Q1": "Yes", "Q3": "Yes"}'
```
