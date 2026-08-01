---
description: Fill out the Gigs incident template from an issue description
---
You are filling out a Gigs incident report from a free-form issue description.

## Issue description

$@

## Instructions

1. Read the issue description above carefully.
2. Produce the **Gigs Incident Template** below, filled out based on the description.
3. For every field, do one of the following — never invent facts:
   - If the description clearly states the value, fill it in. Copy phone numbers exactly as they appear (e.g. `447769676827`) — do not reformat or add spaces or a `+` prefix.
   - If the description does not contain the value, leave the original placeholder text in place (e.g. `DD-MM-YYYY`, `Ipsum Lorem`, `[Yes / No]`, `+XX XXXXX XXXXXX`) so it is obvious the field is unanswered.
   - For `[Yes / No]` fields, replace with the chosen answer only if the description is explicit; otherwise keep `[Yes / No]`.
4. For the `Intermittent or Permanent Issue` section, keep only the line that applies and fill in the frequency / time-of-day details when intermittent. If unclear, keep both lines.
5. Preserve the exact section headings, ordering, and bullet structure of the template.
6. If multiple timed examples are provided, repeat the `Timed Examples of Issue` block for each occurrence.
7. Remove any fields or sections that are entirely unused (i.e. still contain only placeholder values and were not mentioned in the description).
8. Output **only** the completed template — no preamble, no commentary, no code fences.

## Template to fill

GIGS INCIDENT TEMPLATE

Mobile Number
{{issue.custom_field.phone_number}}
PAC Code Port Date
DD-MM-YYYY
Date Issue Started
DD-MM-YYYY
Intermittent or Permanent Issue
Intermitted // Frequency // Time of Day Occurrence
Permanent
Impacted Location
Street Address
Post Town
Post Code
Post Country

Description of issue.
Ipsum Lorem

Actions completed to rule out the device. 
Ipsum Lorem

Impacted services.
Voice
- Unable to make calls [Yes / No]
- Unable to receive calls [Yes / No]
- Dropped calls [Yes / No]
- Poor quality [Yes / No]
- Other
    Ipsum Lorem

Wi-Fi Calling 
- Device is capable of Wi-Fi Calling [Yes / No]
- Device is capable of Wi-Fi Selection [Yes / No]
- Screenshot of Device OS Version (ex. iOS 18.6) [Attached]

SMS Service
- Unable to send SMS [Yes / No]
- SMSC Address Confirmed [Yes / No]
- Unable to receive SMS [Yes / No]
- Other
    Ipsum Lorem

Data Service
- No data [Yes / No]
- Slow data [Yes / No]
- No roaming data [Yes / No]
- Other
    Ipsum Lorem

MMS Service
- Unable to send MMS [Yes / No]
- Unable to receive MMS [Yes / No]

Timed Examples of Issue
- Date & Time: DD-MM-YYYY 00:00
- Mobile Originating Number: +XX XXXXX XXXXXX
- Mobile Terminated Number: +XX XXXXX XXXXXX
- Technology: 2G / 3G / 4G / 5G
- Signal Bars: 1-4 / 4
- (If Voice) Call Result: Error Messages, Tones, Silence
- (If SMS or Data) Error Message:
- (If Data) Attempted Websites:
