import 'package:flutter/material.dart';
import '../models/channel.dart';

/// FinReels channel roster — focused exclusively on:
/// wealth building, entrepreneurship, sales & marketing, personal growth,
/// and stories of how people became rich.
///
/// Removed: The Financial Diet (personal finance/news), School of Hard Knocks.
/// Added: Grant Cardone, Tom Bilyeu, Lewis Howes, Evan Carmichael,
///        Iman Gadzhi, Dan Lok, Tai Lopez, Ryan Pineda.
class ChannelData {
  ChannelData._();

  static const List<Channel> all = [

    // ── How They Got Rich ──────────────────────────────────────────────────────
    Channel(
      id: 'UCiN_1ZoAVaCVpzv0R7f6lcA',
      name: 'Evan Carmichael',
      handle: '@EvanCarmichael',
      description:
          'Breaks down the habits, rules and mindsets of the world\'s most '
          'successful entrepreneurs — Bezos, Musk, Hormozi and more.',
      accentColor: Color(0xFFF59E0B),
      category: 'How They Got Rich',
      focus: 'Success habits & entrepreneur secrets',
      initials: 'EC',
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
      id: 'UC85cBflrQHPH22gLU2N1Hxw',
      name: 'Ryan Pineda',
      handle: '@RyanPineda',
      description:
          'From pro baseball to real estate millionaire. Shows exactly how '
          'he built multiple 7-figure businesses from nothing.',
      accentColor: Color(0xFF14B8A6),
      category: 'How They Got Rich',
      focus: 'Real estate & online business wealth',
      initials: 'RP',
    ),

    // ── Entrepreneurship ───────────────────────────────────────────────────────
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
      id: 'UCQgY17G57xBMb3NNFbVTFsA',
      name: 'Iman Gadzhi',
      handle: '@imangadzhi',
      description:
          'Built a multi-million agency by 18. Teaches online business, '
          'agency building and the exact steps to escape the 9-5.',
      accentColor: Color(0xFF0EA5E9),
      category: 'Entrepreneurship',
      focus: 'Online business & agency building',
      initials: 'IG',
    ),

    // ── Sales & Marketing ──────────────────────────────────────────────────────
    Channel(
      id: 'UCeR0n8d_-y249rnQQye9_Sg',
      name: 'Alex Hormozi',
      handle: '@AlexHormozi',
      description:
          r'Built $100M+ businesses. Teaches sales, marketing, and business '
          'scaling with brutally honest and actionable advice.',
      accentColor: Color(0xFFEF4444),
      category: 'Sales & Business',
      focus: 'Sales, offers & business scaling',
      initials: 'AH',
    ),
    Channel(
      id: 'UCkBT18duRE3V7kPq7AlYMqg',
      name: 'Grant Cardone',
      handle: '@GrantCardone',
      description:
          'The 10X Rule author and real estate king. Teaches aggressive '
          'sales, massive action and how to close any deal.',
      accentColor: Color(0xFFDC2626),
      category: 'Sales & Marketing',
      focus: '10X sales, real estate & closing deals',
      initials: 'GC',
    ),
    Channel(
      id: 'UCkBiUMBGsNAr-Y49y2fLsmA',
      name: 'Dan Lok',
      handle: '@DanLok',
      description:
          'High ticket closer and serial entrepreneur. Teaches premium '
          'sales skills and how to command high prices in any market.',
      accentColor: Color(0xFF1D4ED8),
      category: 'Sales & Marketing',
      focus: 'High ticket sales & closing mastery',
      initials: 'DL',
    ),

    // ── Personal Growth ────────────────────────────────────────────────────────
    Channel(
      id: 'UCnYMOamNKLGVlJgRUbamveA',
      name: 'Tom Bilyeu',
      handle: '@TomBilyeu',
      description:
          'Co-founder of Quest Nutrition (billion-dollar company). Interviews '
          'the world\'s leading experts on mindset, success and human potential.',
      accentColor: Color(0xFF7C3AED),
      category: 'Personal Growth',
      focus: 'Mindset, success & human potential',
      initials: 'TB',
    ),
    Channel(
      id: 'UCKGaClxWkEGP4E3EYe6mZbg',
      name: 'Lewis Howes',
      handle: '@LewisHowes',
      description:
          'School of Greatness — interviews with world-class performers. '
          'Learn the mindset and habits of athletes, billionaires and legends.',
      accentColor: Color(0xFF059669),
      category: 'Personal Growth',
      focus: 'Greatness mindset & high performance',
      initials: 'LH',
    ),
    Channel(
      id: 'UCY_LMaDAoa6hwHKG5c4Y29w',
      name: 'Tai Lopez',
      handle: '@TaiLopez',
      description:
          'Entrepreneur and investor who reads a book a day. Shares the '
          '67 steps and knowledge from the world\'s top minds.',
      accentColor: Color(0xFFF97316),
      category: 'Personal Growth',
      focus: 'Knowledge, books & wealth mindset',
      initials: 'TL',
    ),

    // ── Investing & Wealth ─────────────────────────────────────────────────────
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
      id: 'UCTn-3AmMT7bPiXjFFRnMFcw',
      name: 'Mark Tilbury',
      handle: '@MarkTilbury',
      description:
          'Self-made millionaire sharing the money moves he made to build '
          'real wealth — passive income, investing and financial freedom.',
      accentColor: Color(0xFFFBBF24),
      category: 'Wealth Building',
      focus: 'Passive income & wealth building',
      initials: 'MT',
    ),
    Channel(
      id: 'UCf4s-UF61mNaJMfuVzZFEJA',
      name: "Kevin O'Leary",
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
