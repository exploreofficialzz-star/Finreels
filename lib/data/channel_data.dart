import 'package:flutter/material.dart';
import '../models/channel.dart';

/// Channels focused on: how people got rich, entrepreneurship,
/// sales mastery, wealth mindset, business building.
class ChannelData {
  ChannelData._();

  static const List<Channel> all = [
    Channel(
      id: 'UCmtBqvOp6xHlecDO0Un9O4w',
      name: 'School of Hard Knocks',
      handle: '@theschoolofhardknocks',
      description:
          'Real interviews with millionaires and billionaires sharing exactly '
          'how they built their wealth — raw, unfiltered, and inspiring.',
      accentColor: Color(0xFFF59E0B),
      category: 'How They Got Rich',
      focus: 'Millionaire interviews & wealth secrets',
      initials: 'SK',
    ),
    Channel(
      id: 'UCa-ckhlsx9zgQob2zn_EqMQ',
      name: 'Graham Stephan',
      handle: '@GrahamStephan',
      description:
          'From broke to millionaire by 26 through real estate and smart '
          'investing. No fluff — real numbers, real strategies.',
      accentColor: Color(0xFF10B981),
      category: 'Wealth Building',
      focus: 'Real estate, wealth & financial freedom',
      initials: 'GS',
    ),
    Channel(
      id: 'UCRd5FUNJTpOaVZ-5o8rRZlg',
      name: 'Codie Sanchez',
      handle: '@CodieSanchez',
      description:
          'Contrarian thinker and entrepreneur. Teaches how to buy boring '
          'businesses, build cash flow, and escape the 9-5 forever.',
      accentColor: Color(0xFFEC4899),
      category: 'Entrepreneurship',
      focus: 'Buy businesses & build cash flow',
      initials: 'CS',
    ),
    Channel(
      id: 'UCvC4D8onUfXzvjTOM-dBfEA',
      name: 'Patrick Bet-David',
      handle: '@patrickbetdavid',
      description:
          'Valuetainment — entrepreneur, author and financial expert. '
          'Interviews with top entrepreneurs on how they built empires.',
      accentColor: Color(0xFF3B82F6),
      category: 'Entrepreneurship',
      focus: 'Business strategy & entrepreneurship',
      initials: 'PB',
    ),
    Channel(
      id: 'UCeR0n8d_-y249rnQQye9_Sg',
      name: 'Alex Hormozi',
      handle: '@AlexHormozi',
      description:
          'Built \$100M+ businesses. Teaches sales, marketing, and business '
          'scaling with brutally honest and actionable advice.',
      accentColor: Color(0xFFEF4444),
      category: 'Sales & Business',
      focus: 'Sales, offers & business scaling',
      initials: 'AH',
    ),
    Channel(
      id: 'UCUKYE0BMnMHzrm88tQRqn9A',
      name: 'Gary Vaynerchuk',
      handle: '@garyvee',
      description:
          'Serial entrepreneur, investor and CEO. Raw and real content on '
          'entrepreneurship, social media, and building wealth in the modern era.',
      accentColor: Color(0xFF8B5CF6),
      category: 'Entrepreneurship',
      focus: 'Mindset, hustle & modern business',
      initials: 'GV',
    ),
    Channel(
      id: 'UCTn-3AmMT7bPiXjFFRnMFcw',
      name: 'Mark Tilbury',
      handle: '@MarkTilbury',
      description:
          'Self-made millionaire sharing the money moves he made to build '
          'real wealth — passive income, investing and financial freedom.',
      accentColor: Color(0xFFF97316),
      category: 'Wealth Building',
      focus: 'Passive income & wealth building',
      initials: 'MT',
    ),
    Channel(
      id: 'UCSPYNpQ2fHv9HJ-q6MIMaPw',
      name: 'The Financial Diet',
      handle: '@thefinancialdiet',
      description:
          'Real talk on money, career, and building a life you love. '
          'No judgment — just practical steps to financial freedom.',
      accentColor: Color(0xFF06B6D4),
      category: 'Financial Literacy',
      focus: 'Money mindset & financial freedom',
      initials: 'FD',
    ),
    Channel(
      id: 'UCGy7SkBjcIAgTiwkXEtPnYg',
      name: 'Andrei Jikh',
      handle: '@AndreiJikh',
      description:
          'Went from struggling to financially free. Teaches investing, '
          'passive income and wealth building in an entertaining way.',
      accentColor: Color(0xFF22C55E),
      category: 'Investing',
      focus: 'Passive income & investing',
      initials: 'AJ',
    ),
    Channel(
      id: 'UCf4s-UF61mNaJMfuVzZFEJA',
      name: 'Kevin O\'Leary',
      handle: '@kevinoleary',
      description:
          'Mr. Wonderful from Shark Tank. Straight talk on building '
          'businesses, negotiating deals, and making your money work.',
      accentColor: Color(0xFF6366F1),
      category: 'Entrepreneurship',
      focus: 'Deals, business & wealth mindset',
      initials: 'KO',
    ),
  ];

  static final Map<String, Channel> byId = {
    for (final ch in all) ch.id: ch,
  };

  static Channel get fallback => all.first;
}
