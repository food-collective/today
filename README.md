# Food Collective Today

Tasks and events for everyone on shift at the Berkeley Student Food Collective.
Members log in with their email; the member list, events and each shift's main
task come from Airtable.

## Try it on Heroku (one click)

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://www.heroku.com/deploy)

This creates a **separate** app with its own small database, so nothing in your
current app changes. You only need to paste in your Airtable token.

## What's new in this version

- Brand redesign: Raddish, Pistachio and Soil colors, Chunk Five headings, the BSFC logo.
- "This shift's main task" banner from Airtable at the top of the Tasks page.
- One tap to check off a task, with an Undo button.
- "Checking off as": people on the shared store login can put their own name on what they finish.
- Tasks grouped into "Do these first" and "When you have time", with category filters and counts.
- Finished tasks tucked under "Done this week" instead of piling up forever.
- Events split into "Coming up" and "Recent", with date tiles and map links.
- "Keep me signed in on this device" for the store tablet.
- Faster: no more waiting on Airtable while pages load, no Bootstrap, compressed pages,
  and the Events list no longer stops at 100 events.

## Settings

| Config var | What it does |
| --- | --- |
| `airtable_api_key` | Airtable token (required) |
| `AIRTABLE_BASE_ID`, `AIRTABLE_USERS_TABLE_ID`, `AIRTABLE_TASKS_TABLE_ID`, `AIRTABLE_ANNOUNCEMENTS_TABLE_ID` | Where to read from (used on first setup) |
| `AIRTABLE_SHIFT_TASK_VIEW` | Optional Airtable view whose top task is shown as the shift's main task |
| `AIRTABLE_SHIFT_TASK_FORMULA` | Optional Airtable formula to narrow the shift task further |
| `TASK_CATEGORIES` | Task categories, comma separated (used on first setup) |
| `ADMIN_PASSWORD` | Admin settings password (used on first setup) |

## Running locally

Ruby 3.1.7 and PostgreSQL. `bundle install`, then `bin/rails db:setup` and `bin/rails server`.

The display font is [Chunk Five](https://github.com/theleagueof/chunk) by The League
of Moveable Type, used under the SIL Open Font License (see `public/fonts`).
