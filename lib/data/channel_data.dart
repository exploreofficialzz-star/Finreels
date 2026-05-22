import 'package:flutter/material.dart';

import '../models/channel.dart';

/// FinReels — 10 channels: the 9 specified + School of Hard Knocks.
/// Channel IDs verified against YouTube RSS feed endpoint.
class ChannelData {
  ChannelData._();

  static const List<Channel> all = [
    Channel(
      id: 'UCGq-a57w-aPwyi3pW7XLiHw',
      name: 'The Diary Of A CEO',
      handle: '@thediaryofaceo',
      description:
          'Steven Bartlett interviews the world\'s most successful people — '
          'CEOs, founders and thought leaders on how they built empires.',
      accentColor: Color(0xFF0F172A),
      category: 'Entrepreneurship',
      focus: 'CEO interviews & success mindset',
      initials: 'DC',
    ),
    Channel(
      id: 'UCeR0n8d_-y249rnQQye9_Sg',
      name: 'Alex Hormozi',
      handle: '@alexhormozi',
      description:
          r'Built $100M+ businesses. Brutally honest advice on sales, '
          'offers and scaling. The best business content on YouTube.',
      accentColor: Color(0xFFEF4444),
      category: 'Sales & Business',
      focus: 'Offers, sales & business scaling',
      initials: 'AH',
    ),
    Channel(
      id: 'UCpx-MG7wbF67nEiWuV9nO_g',
      name: 'Iman Gadzhi',
      handle: '@imangadzhi',
      description:
          'Built a multi-million agency by 18. Online business, '
          'agency building and steps to financial freedom.',
      accentColor: Color(0xFF0EA5E9),
      category: 'Entrepreneurship',
      focus: 'Online business & agency building',
      initials: 'IG',
    ),
    Channel(
      id: 'UCZ2QJQzEKf2PUaS7RUQUTLQ',
      name: 'Magnates Media',
      handle: '@magnatesmedia',
      description:
          'Documentary-style deep dives on how the world\'s biggest '
          'companies and entrepreneurs built their empires.',
      accentColor: Color(0xFF7C3AED),
      category: 'How They Got Rich',
      focus: 'Business documentaries & empire stories',
      initials: 'MM',
    ),
    Channel(
      id: 'UCWpR4wMIlkE7JZnANqUMaQg',
      name: 'My First Million',
      handle: '@myfirstmillionpod',
      description:
          'Sam Parr and Shaan Puri break down how people made their first '
          'million — business ideas, case studies and wealth strategies.',
      accentColor: Color(0xFF10B981),
      category: 'Entrepreneurship',
      focus: 'Business ideas & wealth case studies',
      initials: 'MF',
    ),
    Channel(
      id: 'UCGHbFkzNANwLy7GOdXs17Jg',
      name: 'HubSpot Marketing',
      handle: '@hubspotmarketing',
      description:
          'Actionable marketing strategies and growth tactics from '
          "HubSpot — the world's leading CRM platform.",
      accentColor: Color(0xFFFF7A59),
      category: 'Sales & Marketing',
      focus: 'Marketing strategies & business growth',
      initials: 'HM',
    ),
    Channel(
      id: 'UCVOeFxCnmHE2pqJ5XEPQ-pg',
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
      id: 'UCs_6DLTDKH6cFCzgm_C0Fog',
      name: 'Dan Lok',
      handle: '@danlok',
      description:
          'High ticket closer and serial entrepreneur. Premium sales '
          'skills and how to command high prices in any market.',
      accentColor: Color(0xFF1D4ED8),
      category: 'Sales & Marketing',
      focus: 'High ticket sales & closing',
      initials: 'DL',
    ),
    Channel(
      id: 'UCOIhB9fpQE_2GlRSLIAGXUg',
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
  ];

  static final Map<String, Channel> byId = {
    for (final ch in all) ch.id: ch,
  };

  static Channel get fallback => all.first;
}
