import 'package:flutter/material.dart';
import '../models/channel.dart';

class ChannelData {
  ChannelData._();

  static const List<Channel> all = [
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
          'saving, real estate, credit scores and financial freedom with a '
          'no-nonsense, honest approach to building wealth.',
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
          'Makes personal finance accessible and entertaining for everyone. '
          'Covers budgeting, career, lifestyle, and money mindset — the go-to '
          'channel for millennials and Gen Z building their financial foundation.',
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
          'Personal finance, investing, and financial minimalism with unique '
          'flair. Magic tricks meet market insights in this entertaining and '
          'educational guide to building real wealth.',
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
          'Actionable wealth-building strategies explained with crystal-clear '
          'whiteboard-style breakdowns. Covers stocks, real estate, early '
          'retirement (FIRE), and tax optimisation.',
      accentColor: Color(0xFF3B82F6),
      category: 'Wealth Building',
      focus: 'Stocks, real estate & FIRE',
      initials: 'WF',
    ),
  ];
}
