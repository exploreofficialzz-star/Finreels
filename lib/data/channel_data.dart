import 'package:flutter/material.dart';

import '../models/channel.dart';

/// FinReels — 10 channels, all IDs verified directly from YouTube channel pages.
///
/// Root cause of "only 2 channels showing":
///   8 out of 10 channel IDs in the original file were WRONG — they did not
///   correspond to the actual YouTube channels. Wrong IDs return an empty XML
///   feed (the channel exists but has no videos under that ID), or a 404.
///   Only Diary of A CEO and School of Hard Knocks had correct IDs.
///
/// All IDs below were confirmed by fetching the channel page directly and
/// reading the Channel ID from the page source / RSS link.
class ChannelData {
  ChannelData._();

  static const List<Channel> all = [
    Channel(
      // Verified: youtube.com/channel/UCGq-a57w-aPwyi3pW7XLiHw ✓
      id: 'UCGq-a57w-aPwyi3pW7XLiHw',
      name: 'The Diary Of A CEO',
      handle: '@thediaryofaceo',
      description:
          "Steven Bartlett interviews the world's most successful people — "
          'CEOs, founders and thought leaders on how they built empires.',
      accentColor: Color(0xFF0F172A),
      category: 'Entrepreneurship',
      focus: 'CEO interviews & success mindset',
      initials: 'DC',
    ),
    Channel(
      // Corrected: was UCeR0n8d_-y249rnQQye9_Sg (wrong)
      // Verified: youtube.com/channel/UCUyDOdBWhC1MCxEjC46d-zw ✓
      id: 'UCUyDOdBWhC1MCxEjC46d-zw',
      name: 'Alex Hormozi',
      handle: '@AlexHormozi',
      description:
          r'Built $100M+ businesses. Brutally honest advice on sales, '
          'offers and scaling. The best business content on YouTube.',
      accentColor: Color(0xFFEF4444),
      category: 'Sales & Business',
      focus: 'Offers, sales & business scaling',
      initials: 'AH',
    ),
    Channel(
      // Corrected: was UCpx-MG7wbF67nEiWuV9nO_g (wrong)
      // Verified: youtube.com/channel/UCQ4FNww3XoNgqIlkBqEAVCg ✓
      id: 'UCQ4FNww3XoNgqIlkBqEAVCg',
      name: 'Iman Gadzhi',
      handle: '@ImanGadzhi',
      description:
          'Built a multi-million agency by 18. Online business, '
          'agency building and steps to financial freedom.',
      accentColor: Color(0xFF0EA5E9),
      category: 'Entrepreneurship',
      focus: 'Online business & agency building',
      initials: 'IG',
    ),
    Channel(
      // Corrected: was UCZ2QJQzEKf2PUaS7RUQUTLQ (wrong)
      // Verified: youtube.com/c/MagnatesMedia → UCE4Gn00XZbpWvGUfIslT-tA ✓
      id: 'UCE4Gn00XZbpWvGUfIslT-tA',
      name: 'Magnates Media',
      handle: '@MagnatesMedia',
      description:
          "Documentary-style deep dives on how the world's biggest "
          'companies and entrepreneurs built their empires.',
      accentColor: Color(0xFF7C3AED),
      category: 'How They Got Rich',
      focus: 'Business documentaries & empire stories',
      initials: 'MM',
    ),
    Channel(
      // Corrected: was UCWpR4wMIlkE7JZnANqUMaQg (wrong)
      // Verified: youtube.com/@MyFirstMillionPod → UCyaN6mg5u8Cjy2ZI4ikWaug ✓
      id: 'UCyaN6mg5u8Cjy2ZI4ikWaug',
      name: 'My First Million',
      handle: '@MyFirstMillionPod',
      description:
          'Sam Parr and Shaan Puri break down how people made their first '
          'million — business ideas, case studies and wealth strategies.',
      accentColor: Color(0xFF10B981),
      category: 'Entrepreneurship',
      focus: 'Business ideas & wealth case studies',
      initials: 'MF',
    ),
    Channel(
      // Corrected: was UCGHbFkzNANwLy7GOdXs17Jg (wrong)
      // Verified: youtube.com/channel/UCVeuau7DLrg7zlAjxxDbdww ✓
      id: 'UCVeuau7DLrg7zlAjxxDbdww',
      name: 'HubSpot Marketing',
      handle: '@HubSpotMarketing',
      description:
          'Actionable marketing strategies and growth tactics from '
          "HubSpot — the world's leading CRM platform.",
      accentColor: Color(0xFFFF7A59),
      category: 'Sales & Marketing',
      focus: 'Marketing strategies & business growth',
      initials: 'HM',
    ),
    Channel(
      // Corrected: was UCVOeFxCnmHE2pqJ5XEPQ-pg (wrong)
      // Verified: youtube.com/c/NeilPatel → UCl-Zrl0QhF66lu1aGXaTbfw ✓
      id: 'UCl-Zrl0QhF66lu1aGXaTbfw',
      name: 'Neil Patel',
      handle: '@neilpatel',
      description:
          "The world's top digital marketer. SEO, content "
          'marketing and how to grow a business online from scratch.',
      accentColor: Color(0xFF2563EB),
      category: 'Sales & Marketing',
      focus: 'Digital marketing & SEO',
      initials: 'NP',
    ),
    Channel(
      // Corrected: was UCs_6DLTDKH6cFCzgm_C0Fog (wrong, off by a few chars)
      // Verified: youtube.com/c/DanLok → UCs_6DXZROU29pLvgQdCx4Ww ✓
      id: 'UCs_6DXZROU29pLvgQdCx4Ww',
      name: 'Dan Lok',
      handle: '@DanLok',
      description:
          'High ticket closer and serial entrepreneur. Premium sales '
          'skills and how to command high prices in any market.',
      accentColor: Color(0xFF1D4ED8),
      category: 'Sales & Marketing',
      focus: 'High ticket sales & closing',
      initials: 'DL',
    ),
    Channel(
      // Corrected: was UCOIhB9fpQE_2GlRSLIAGXUg (wrong)
      // Verified: youtube.com/channel/UCsQiYDzi0UtpdDIe7_DpcLw ✓
      id: 'UCsQiYDzi0UtpdDIe7_DpcLw',
      name: 'Jordan Platten',
      handle: '@jordanplatten',
      description:
          'Social media marketing agency expert. Build a 6-figure '
          'SMMA and get high-paying clients.',
      accentColor: Color(0xFFF59E0B),
      category: 'Sales & Marketing',
      focus: 'SMMA & social media marketing',
      initials: 'JP',
    ),
    Channel(
      // Verified: youtube.com/channel/UCmtBqvOp6xHlecDO0Un9O4w ✓
      id: 'UCmtBqvOp6xHlecDO0Un9O4w',
      name: 'School of Hard Knocks',
      handle: '@theschoolofhardknocks',
      description:
          'Raw interviews with self-made millionaires sharing exactly '
          'how they built their wealth — struggles, turning points and '
          'strategies that really worked.',
      accentColor: Color(0xFFD97706),
      category: 'How They Got Rich',
      focus: 'Millionaire interviews & wealth journeys',
      initials: 'SK',
    ),
    Channel(
      // Verified: youtube.com/@vthembekwayo → UC_Ktic72t5bDX_3go_9u_pg ✓
      id: 'UC_Ktic72t5bDX_3go_9u_pg',
      name: 'Vusi Thembekwayo',
      handle: '@vthembekwayo',
      description:
          'Global business strategist, venture capitalist and keynote speaker. '
          '480+ keynotes across 6 continents. Founder & CEO of MyGrowthFund. '
          'Unfiltered insights on leadership, disruption and the founder mindset.',
      accentColor: Color(0xFF16A34A),
      category: 'Entrepreneurship',
      focus: 'Leadership, strategy & disruption',
      initials: 'VT',
    ),
    Channel(
      // Verified: youtube.com/@marketing-explained → UCM_PsKK4kvrOTNrHlsgK6pQ ✓
      id: 'UCM_PsKK4kvrOTNrHlsgK6pQ',
      name: 'Marketing Explained',
      handle: '@marketing-explained',
      description:
          'Digital marketing explained simply — HubSpot tutorials, '
          'quick tips and strategies from Cyberclick. '
          'Inbound, SEO, paid media, social and more.',
      accentColor: Color(0xFFDB4437),
      category: 'Sales & Marketing',
      focus: 'Digital marketing tutorials & strategies',
      initials: 'ME',
    ),
  ];

  static final Map<String, Channel> byId = {
    for (final ch in all) ch.id: ch,
  };

  static Channel get fallback => all.first;
}
