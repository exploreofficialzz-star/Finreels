import 'package:flutter/material.dart';

import '../models/channel.dart';

class ChannelData {
  ChannelData._();

  static const List<Channel> all = [
    // ── Core 5 ─────────────────────────────────────────────────────────────────
    Channel(
      id: 'UCmtBqvOp6xHlecDO0Un9O4w',
      name: 'School of Hard Knocks',
      handle: '@theschoolofhardknocks',
      description:
          'A media company promoting financial literacy with 1.5M+ followers. '
          'Features "10 Questions with a Millionaire" and interviews with top '
          'professionals and entrepreneurs to bring mentorship at scale.',
      accentColor: Color(0xFFF59E0B),
      category: 'Financial Literacy',
      focus: 'Millionaire interviews & career mentorship',
      initials: 'SK',
    ),
    Channel(
      id: 'UCa-ckhlsx9zgQob2zn_EqMQ',
      name: 'Graham Stephan',
      handle: '@GrahamStephan',
      description:
          'Real estate investor who became a millionaire by 26. Covers investing, '
          'saving, real estate, credit scores and financial freedom.',
      accentColor: Color(0xFF10B981),
      category: 'Personal Finance',
      focus: 'Real estate, investing & saving',
      initials: 'GS',
    ),
    Channel(
      id: 'UCSPYNpQ2fHv9HJ-q6MIMaPw',
      name: 'The Financial Diet',
      handle: '@thefinancialdiet',
      description:
          'Makes personal finance accessible and entertaining. Covers budgeting, '
          'career, lifestyle, and money mindset.',
      accentColor: Color(0xFFEC4899),
      category: 'Personal Finance',
      focus: 'Budgeting, career & lifestyle',
      initials: 'FD',
    ),
    Channel(
      id: 'UCGy7SkBjcIAgTiwkXEtPnYg',
      name: 'Andrei Jikh',
      handle: '@AndreiJikh',
      description:
          'Personal finance, investing, and financial minimalism with unique flair. '
          'Magic tricks meet market insights.',
      accentColor: Color(0xFF8B5CF6),
      category: 'Investing',
      focus: 'Stocks, crypto & minimalism',
      initials: 'AJ',
    ),
    Channel(
      id: 'UCL_v4tC0nkTCeAEeATAvuXw',
      name: 'Whiteboard Finance',
      handle: '@WhiteboardFinance',
      description:
          'Actionable wealth-building strategies with whiteboard-style breakdowns. '
          'Covers stocks, real estate, FIRE, and tax optimisation.',
      accentColor: Color(0xFF3B82F6),
      category: 'Wealth Building',
      focus: 'Stocks, real estate & FIRE',
      initials: 'WF',
    ),

    // ── Additional Channels ─────────────────────────────────────────────────────
    Channel(
      id: 'UCTOuJO9znANM4cNEbRVxwkA',
      name: 'Nate O\'Brien',
      handle: '@NateOBrien',
      description:
          'Minimalism, financial independence, and building wealth intentionally. '
          'Practical tips for saving, investing and living with less.',
      accentColor: Color(0xFF06B6D4),
      category: 'Minimalism & FIRE',
      focus: 'Minimalism, saving & independence',
      initials: 'NO',
    ),
    Channel(
      id: 'UCTn-3AmMT7bPiXjFFRnMFcw',
      name: 'Mark Tilbury',
      handle: '@MarkTilbury',
      description:
          'Self-made millionaire sharing honest money advice. Covers investing, '
          'passive income, and building wealth from scratch.',
      accentColor: Color(0xFFF97316),
      category: 'Wealth Building',
      focus: 'Passive income & investing',
      initials: 'MT',
    ),
    Channel(
      id: 'UCjemQfjaXAzA-95RKoy9n_g',
      name: 'Jarrad Morrow',
      handle: '@JarradMorrow',
      description:
          'Index fund investing, ETFs, and dividend strategies. No-nonsense '
          'approach to building a passive income portfolio.',
      accentColor: Color(0xFF22C55E),
      category: 'Investing',
      focus: 'Index funds, ETFs & dividends',
      initials: 'JM',
    ),
    Channel(
      id: 'UCRd5FUNJTpOaVZ-5o8rRZlg',
      name: 'Humphrey Yang',
      handle: '@HumphreyYang',
      description:
          'Personal finance made fun with short-form explanations of investing, '
          'budgeting, taxes, and building net worth.',
      accentColor: Color(0xFFEF4444),
      category: 'Personal Finance',
      focus: 'Budgeting, taxes & net worth',
      initials: 'HY',
    ),
    Channel(
      id: 'UCf4s-UF61mNaJMfuVzZFEJA',
      name: 'Kevin O\'Leary',
      handle: '@kevinoleary',
      description:
          'Shark Tank investor sharing real-world business, investing and '
          'money management wisdom from decades of entrepreneurship.',
      accentColor: Color(0xFF6366F1),
      category: 'Entrepreneurship',
      focus: 'Business, investing & entrepreneurship',
      initials: 'KO',
    ),
  ];

  /// Channel map by ID for O(1) lookup
  static final Map<String, Channel> byId = {
    for (final ch in all) ch.id: ch,
  };

  /// Fallback channel for unknown IDs
  static Channel get fallback => all.first;
}
