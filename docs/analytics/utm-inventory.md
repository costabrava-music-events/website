# UTM convention and inventory

This inventory uses the canonical site URLs as landing pages. Keep the UTM
values lowercase, use underscores as separators, and never put a name, email,
phone number or other personal data in a UTM value.

## Convention

| Parameter | Rule | Examples |
| --- | --- | --- |
| `utm_source` | Origin platform or partner slug. | `instagram`, `whatsapp`, `google`, `can_marc` |
| `utm_medium` | Controlled channel. | `social`, `messaging`, `organic`, `referral` |
| `utm_campaign` | Business initiative and year. | `evergreen_2026`, `google_business_profile`, `partners_2026` |
| `utm_content` | Placement or creative. | `bio`, `post`, `story`, `contact_link`, `website_button` |
| `utm_term` | Optional non-personal keyword only. | `wedding_dj` |

Use `utm_source=instagram` for Instagram profile links, posts and Stories.
Use `utm_content` to distinguish those placements. Use `utm_source=google` and
`utm_medium=organic` for the Google Business Profile website link so GA4 keeps
it in Organic Search. WhatsApp links use `messaging`. Each partner gets a
stable lowercase slug and `referral`.

## Active links

All examples below were generated from canonical URLs in `sitemap.xml` and
are ready to paste into the relevant platform.

| Channel / placement | Tagged URL | Source | Medium | Campaign | Date | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Instagram profile bio | `https://costabravamusicevents.com/?utm_source=instagram&utm_medium=social&utm_campaign=evergreen_2026&utm_content=bio` | `instagram` | `social` | `evergreen_2026` | 2026-08-21 | active |
| Instagram feed post | `https://costabravamusicevents.com/es/dj-bodas-costa-brava.html?utm_source=instagram&utm_medium=social&utm_campaign=evergreen_2026&utm_content=post` | `instagram` | `social` | `evergreen_2026` | 2026-08-21 | active |
| Instagram Story | `https://costabravamusicevents.com/es/blog-boda-destino-costa-brava-musica-produccion.html?utm_source=instagram&utm_medium=social&utm_campaign=evergreen_2026&utm_content=story` | `instagram` | `social` | `evergreen_2026` | 2026-08-21 | active |
| WhatsApp message | `https://costabravamusicevents.com/contact.html?utm_source=whatsapp&utm_medium=messaging&utm_campaign=evergreen_2026&utm_content=contact_link` | `whatsapp` | `messaging` | `evergreen_2026` | 2026-08-21 | active |
| Google Business Profile | `https://costabravamusicevents.com/contact.html?utm_source=google&utm_medium=organic&utm_campaign=google_business_profile&utm_content=website_button` | `google` | `organic` | `google_business_profile` | 2026-08-21 | active |
| Can Marc | `https://costabravamusicevents.com/?utm_source=can_marc&utm_medium=referral&utm_campaign=partners_2026&utm_content=website_link` | `can_marc` | `referral` | `partners_2026` | 2026-08-21 | active |
| La Cala Navega | `https://costabravamusicevents.com/?utm_source=la_cala_navega&utm_medium=referral&utm_campaign=partners_2026&utm_content=website_link` | `la_cala_navega` | `referral` | `partners_2026` | 2026-08-21 | active |
| BCN en las Alturas | `https://costabravamusicevents.com/?utm_source=bcn_en_las_alturas&utm_medium=referral&utm_campaign=partners_2026&utm_content=website_link` | `bcn_en_las_alturas` | `referral` | `partners_2026` | 2026-08-21 | active |
| Flan Sin Nata | `https://costabravamusicevents.com/?utm_source=flan_sin_nata&utm_medium=referral&utm_campaign=partners_2026&utm_content=website_link` | `flan_sin_nata` | `referral` | `partners_2026` | 2026-08-21 | active |
| Bodalia | `https://costabravamusicevents.com/es/dj-bodas-costa-brava.html?utm_source=bodalia&utm_medium=referral&utm_campaign=partners_2026&utm_content=website_link` | `bodalia` | `referral` | `partners_2026` | 2026-08-21 | active |

## Operating rules

- Tag the first site URL a person opens from the external channel.
- Do not add UTM parameters to canonical tags, sitemap entries or internal links.
- Keep one row per externally published link and update the date when its destination or campaign changes.
- The site stores only the allowlisted UTM fields from the first landing URL for the browser session. It does not store form values or full URLs.
