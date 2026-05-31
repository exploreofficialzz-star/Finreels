// ── In-app key insights for books that are not freely available online ────────
// Each entry provides real, substantive chapter-by-chapter insights so the
// user gets genuine value. A "Get Full Book" link directs them to purchase.

class BookChapter {
  final String title;
  final String body;
  final List<String> keyPoints;
  const BookChapter({
    required this.title,
    required this.body,
    this.keyPoints = const [],
  });
}

class BookInsightData {
  final String id;
  final String title;
  final String author;
  final String tagline;
  final String intro;
  final List<BookChapter> chapters;
  final String purchaseUrl; // Amazon affiliate or Google Play Books
  const BookInsightData({
    required this.id,
    required this.title,
    required this.author,
    required this.tagline,
    required this.intro,
    required this.chapters,
    required this.purchaseUrl,
  });
}

const List<BookInsightData> kBookInsights = [

  // ── Think and Grow Rich ────────────────────────────────────────────────────
  BookInsightData(
    id: 'book_think_grow',
    title: 'Think and Grow Rich',
    author: 'Napoleon Hill',
    tagline: '13 principles of wealth distilled from 500+ successful people.',
    intro:
        'Napoleon Hill spent 20 years interviewing over 500 of America\'s most '
        'successful people — including Andrew Carnegie, Henry Ford, and Thomas '
        'Edison — to distil the common principles behind extraordinary wealth. '
        'First published in 1937, this book has sold over 100 million copies '
        'and remains one of the best-selling self-help books of all time.',
    chapters: [
      BookChapter(
        title: '1. Thoughts Are Things',
        body:
            'Everything begins with a thought. Edwin C. Barnes had nothing but '
            'a burning desire to work with Edison — no money, no connections. '
            'He hitchhiked to Edison\'s lab and eventually became his partner. '
            'The starting point of all achievement is a definiteness of purpose '
            'backed by a burning desire for its fulfilment.',
        keyPoints: [
          'Desire is the starting point of all achievement',
          'A burning, obsessive goal separates the wealthy from the wishing',
          'Thoughts backed by emotion become reality faster',
        ],
      ),
      BookChapter(
        title: '2. Desire — The First Step to Riches',
        body:
            'Wishing for wealth won\'t cut it. You need a white-hot, specific '
            'desire. Hill\'s six-step method: fix the exact amount you want, '
            'decide what you\'ll give in return, set a definite date, make a '
            'plan, write it all out, and read it aloud twice daily with emotion.',
        keyPoints: [
          'Be specific — "I want more money" is not a desire, it\'s a wish',
          'Read your written desire statement every morning and night',
          'Burn all mental bridges back to average — total commitment',
        ],
      ),
      BookChapter(
        title: '3. Faith — Visualising and Believing',
        body:
            'Faith is a state of mind you can develop through auto-suggestion — '
            'repeated affirmations to your subconscious. When you truly believe '
            'you will achieve something, your mind begins to find paths your '
            'conscious mind would have dismissed. The subconscious cannot tell '
            'the difference between real and vividly imagined experience.',
        keyPoints: [
          'Repeat your goal to yourself with emotion, not just words',
          'Act as if you have already achieved your goal',
          'Self-confidence built through repetition becomes unshakeable',
        ],
      ),
      BookChapter(
        title: '4. Auto-Suggestion — The Medium of Influence',
        body:
            'Your subconscious mind absorbs every thought you feed it. '
            'Auto-suggestion is deliberately programming it. Combine '
            'your written statement with emotion and repetition. Neutral '
            'statements do nothing — the subconscious responds only to thoughts '
            'charged with feeling.',
        keyPoints: [
          'Read your desire statement with genuine emotion',
          'Visualise yourself already in possession of the money',
          'Concentrate on these thoughts just before sleep',
        ],
      ),
      BookChapter(
        title: '5. Specialised Knowledge',
        body:
            'General knowledge is of little use in wealth building. Henry Ford '
            'had barely a primary school education, yet he employed specialists '
            'who knew everything he needed. The secret: know how to acquire and '
            'organise specialised knowledge, not necessarily possess it yourself.',
        keyPoints: [
          'School teaches you how to learn, not necessarily what to earn',
          'Your network of specialists multiplies your own knowledge',
          'Identify the gap in knowledge between you and your goal — then fill it',
        ],
      ),
      BookChapter(
        title: '6. Imagination — The Workshop of the Mind',
        body:
            'Hill distinguishes synthetic imagination (rearranging existing ideas) '
            'from creative imagination (hunches, inspiration from Infinite '
            'Intelligence). Most wealth is built through synthetic imagination — '
            'combining existing products, services, or systems in new ways.',
        keyPoints: [
          'Most fortunes are built by combining old ideas in new ways',
          'Your imagination grows stronger with deliberate use',
          'Ideas are the beginning point of all fortunes',
        ],
      ),
      BookChapter(
        title: '7. Organised Planning',
        body:
            'No individual has sufficient knowledge or effort to build great '
            'wealth alone. The Master Mind — a group of people aligned toward '
            'a single goal — multiplies your brainpower. Every great industrialist '
            'used a Master Mind group. Temporary defeat is not failure; it is '
            'a signal to create a better plan.',
        keyPoints: [
          'Form or join a mastermind group aligned to your goals',
          'Failure is just temporary defeat — change the plan, not the goal',
          'Persistence and definite plans beat talent and luck',
        ],
      ),
      BookChapter(
        title: '8. Decision & Persistence',
        body:
            'Successful people reach decisions promptly and change them slowly. '
            'Unsuccessful people decide slowly and change often. Persistence is '
            'the sustained effort required to accumulate faith. Most people give '
            'up at the first sign of opposition — this is why wealth is rare.',
        keyPoints: [
          'Make decisions quickly and change them slowly',
          'Persistence is to character what carbon is to steel',
          'Most people quit one step before the breakthrough',
        ],
      ),
      BookChapter(
        title: '9. The Subconscious Mind & The Brain',
        body:
            'The subconscious is a broadcasting and receiving station. It works '
            'continuously even while you sleep, connecting your thoughts to '
            'opportunities and people. Positive emotions — desire, faith, love, '
            'enthusiasm — are the fuel. Fear, jealousy, and doubt short-circuit '
            'the whole system.',
        keyPoints: [
          'Feed your subconscious positive, specific thoughts daily',
          'Negative emotions block creative intelligence',
          'Your brain literally picks up on the thoughts of those around you',
        ],
      ),
      BookChapter(
        title: '10. The Sixth Sense',
        body:
            'After mastering all 13 principles, a creative faculty develops — '
            'a form of heightened intuition that warns of danger and reveals '
            'opportunity. Hill called this the Sixth Sense. It is the product '
            'of years of deliberate self-development, not something granted to '
            'a lucky few.',
        keyPoints: [
          'Intuition sharpens as a result of deliberately practising the principles',
          'The 13 principles work together as a single system',
          'Self-mastery, not luck, is the true differentiator',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/1585424331',
  ),

  // ── Rich Dad Poor Dad ──────────────────────────────────────────────────────
  BookInsightData(
    id: 'book_rich_dad',
    title: 'Rich Dad Poor Dad',
    author: 'Robert T. Kiyosaki',
    tagline: 'Assets vs liabilities and the mindset shift to build wealth.',
    intro:
        'Robert Kiyosaki grew up with two father figures: his highly educated '
        'biological father (Poor Dad) who believed in job security and a '
        'government pension, and his best friend\'s father (Rich Dad) who '
        'believed in building assets and having money work for you. The '
        'contrast between their financial philosophies changed Kiyosaki\'s '
        'life — and has since changed tens of millions of others.',
    chapters: [
      BookChapter(
        title: '1. The Rich Don\'t Work for Money',
        body:
            'Poor and middle-class people work for money. The rich have money '
            'work for them. Kiyosaki\'s Rich Dad paid him almost nothing as a '
            'child — on purpose. The lesson: emotions (fear and greed) drive '
            'most people\'s financial decisions. Fear of losing money keeps '
            'people in safe jobs. Greed keeps them buying luxuries they can\'t '
            'afford. Rich Dad taught him to observe those emotions without '
            'letting them dictate decisions.',
        keyPoints: [
          'Fear of poverty drives most people into the rat race',
          'Emotions are the biggest obstacle to financial intelligence',
          'Learn to use your feelings, not be used by them',
        ],
      ),
      BookChapter(
        title: '2. Why Teach Financial Literacy?',
        body:
            'The single most important lesson: the difference between an asset '
            'and a liability — and buy assets. An asset puts money IN your '
            'pocket. A liability takes money OUT. A house you live in is a '
            'liability (mortgage, taxes, maintenance all drain cash). '
            'A rental property that earns income is an asset. Most people '
            'think their house is their biggest asset. It is usually their '
            'biggest liability.',
        keyPoints: [
          'Asset: puts money in your pocket (rental income, dividends, royalties)',
          'Liability: takes money out (mortgage, car loan, credit card debt)',
          'The rich acquire assets. The poor and middle class acquire liabilities',
        ],
      ),
      BookChapter(
        title: '3. Mind Your Own Business',
        body:
            'Keep your day job, but start building your asset column. Your '
            'profession is not your business. A bank employee\'s profession '
            'is banking; their business should be building real estate, stocks, '
            'or intellectual property. Don\'t spend everything you earn. '
            'Buy income-generating assets first — luxuries come from the cash '
            'flow those assets generate.',
        keyPoints: [
          'Your job is your income source, not your wealth source',
          'Build your asset column on the side',
          'Buy luxuries with asset income, not salary',
        ],
      ),
      BookChapter(
        title: '4. The History of Taxes',
        body:
            'The tax system was originally designed to tax the rich. The '
            'middle class ended up carrying most of the burden. Corporations '
            'are legal entities that pay tax on what is left AFTER expenses. '
            'Employees pay tax BEFORE expenses. The rich use corporations and '
            'the tax code legally to protect and grow their wealth. Financial '
            'IQ includes understanding tax law.',
        keyPoints: [
          'Corporations pay expenses first, tax on what\'s left',
          'Employees pay tax first, expenses with what\'s left',
          'Understanding tax law is a core financial skill',
        ],
      ),
      BookChapter(
        title: '5. The Rich Invent Money',
        body:
            'The single most powerful asset we all have is our mind. The '
            'trained mind can create enormous wealth. "I can\'t afford it" '
            'shuts down your brain. "How can I afford it?" opens it up. '
            'Financial genius is developed: accounting, investing, '
            'understanding markets, and the law combine to create opportunity '
            'where others see nothing.',
        keyPoints: [
          'Replace "I can\'t afford it" with "How can I afford it?"',
          'Financial IQ = accounting + investing + market knowledge + law',
          'Opportunities are created by those who see them, not waited for',
        ],
      ),
      BookChapter(
        title: '6. Work to Learn — Don\'t Work for Money',
        body:
            'Job security meant everything to Poor Dad. Learning meant '
            'everything to Rich Dad. Work for what you learn, not just what '
            'you earn. Take a second job at a company that teaches marketing, '
            'communication, or management — skills the school system doesn\'t '
            'teach. The world is full of talented poor people who never learned '
            'to sell or manage.',
        keyPoints: [
          'Choose jobs for what you learn, not just what you earn',
          'The ability to sell is the #1 skill for wealth building',
          'Most talented people stay poor because they can\'t communicate their value',
        ],
      ),
      BookChapter(
        title: '7. Overcoming Obstacles',
        body:
            'Five main reasons even financially literate people fail: fear of '
            'losing money, cynicism, laziness, bad habits, and arrogance. '
            'Losers avoid failure; winners fail and learn. Cynicism is '
            'paralysing — the voice that says "what if it doesn\'t work?" '
            'Laziness disguises itself as "I\'m busy." The antidote to '
            'laziness is greed — a healthy desire for a better life.',
        keyPoints: [
          'Fear of losing money is normal — winners feel it and act anyway',
          'Cynicism keeps you poor; doubt everything except your own potential',
          'Laziness often hides as busyness — the real question is priorities',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/1612680194',
  ),

  // ── The Psychology of Money ────────────────────────────────────────────────
  BookInsightData(
    id: 'book_psychology_money',
    title: 'The Psychology of Money',
    author: 'Morgan Housel',
    tagline: '19 short stories on wealth, greed and happiness.',
    intro:
        'Doing well with money has little to do with how smart you are and '
        'everything to do with how you behave. Morgan Housel argues that '
        'finance is taught as a maths-based discipline, but in real life it '
        'is driven by psychology — emotion, ego, bias, and narrative. These '
        '19 short chapters explore the ways people think about money and why '
        'good behaviour, not high IQ, is the real wealth driver.',
    chapters: [
      BookChapter(
        title: '1. No One\'s Crazy',
        body:
            'Your personal experience with money makes up perhaps 0.00001% '
            'of what has happened in the world but maybe 80% of how you think '
            'the world works. Someone who grew up during the Great Depression '
            'will forever approach risk differently from someone who grew up '
            'in the 1990s bull market. Neither is irrational — they are '
            'products of their experience.',
        keyPoints: [
          'Everyone has a unique financial worldview shaped by their personal history',
          'What looks irrational from the outside is often rational from the inside',
          'Humility: judge financial decisions less harshly when you lack context',
        ],
      ),
      BookChapter(
        title: '2. Luck & Risk',
        body:
            'Bill Gates went to one of the only high schools in the world with '
            'a computer in 1968. His classmate Kent Evans, equally talented '
            'and hardworking, died in a mountaineering accident before '
            'graduation. Nothing separates them except luck and risk. '
            'When judging success, you should always factor in the role of '
            'luck — including your own.',
        keyPoints: [
          'Luck and risk are two sides of the same coin',
          'Be careful who you praise for success and blame for failure',
          'Focus on broad patterns, not individual case studies',
        ],
      ),
      BookChapter(
        title: '3. Never Enough',
        body:
            r'Rajat Gupta had everything — $100 million net worth, Goldman '
            'Sachs board member — and went to prison for insider trading to '
            'get more. The hardest financial skill is getting the goalposts '
            'to stop moving. Enough is realising that the desire for more '
            'will make you risk what you have and need for what you don\'t.',
        keyPoints: [
          'Social comparison is the most dangerous game in finance',
          '"Enough" is a superpower — cultivate it deliberately',
          'Never risk what you have and need for what you want but don\'t need',
        ],
      ),
      BookChapter(
        title: '4. Compounding',
        body:
            r"Warren Buffett's net worth at 65 was $60 billion. His net worth "
            r'today is $80+ billion. Most of his wealth came AFTER he qualified '
            'for Social Security. Compounding is counter-intuitive: the curve '
            'starts shallow for so long that most people give up. The secret '
            'isn\'t returns — it\'s time in the market.',
        keyPoints: [
          '96% of Warren Buffett\'s wealth was earned after age 65',
          'Good returns for a very long time beats great returns for a short time',
          'The most powerful force in personal finance is time, not rate of return',
        ],
      ),
      BookChapter(
        title: '5. Getting Wealthy vs Staying Wealthy',
        body:
            'Getting money and keeping money are two different skills. Getting '
            'money requires optimism and taking risk. Keeping money requires '
            'humility and fear that what you\'ve made can be taken away just '
            'as fast. Survival is the prerequisite to compounding. You only '
            'have to get rich once — the plan that allows you to sleep at '
            'night is the correct one.',
        keyPoints: [
          'More than big returns, you need to stay solvent and not panic',
          'Planning for surprises is more important than planning for the expected',
          'Financial endurance beats financial genius',
        ],
      ),
      BookChapter(
        title: '6. Freedom',
        body:
            'The highest dividend money pays is control over your time. The '
            'ability to do what you want, when you want, with who you want, '
            'for as long as you want — that is the ultimate form of wealth. '
            'Not luxury cars. Not big houses. The ability to wake up and say '
            '"I do what I want today" is priceless. Yet most people '
            'underestimate this and overestimate the joy of things.',
        keyPoints: [
          'Time autonomy is the real return on financial independence',
          'Happiness is less about income and more about control of your schedule',
          'Buy time, not just things',
        ],
      ),
      BookChapter(
        title: '7. Reasonable > Rational',
        body:
            'Academic finance says be rational. Real life says be reasonable. '
            'A strategy you can stick to for 30 years in a terrible market '
            'beats a theoretically optimal strategy you abandon in year 3. '
            'Housel\'s advice: pick an investment strategy that is "good '
            'enough" AND that matches your personality so you can actually '
            'follow it through every market cycle.',
        keyPoints: [
          'The best strategy is the one you\'ll actually stick to',
          'Optimise for sleeping at night, not maximum theoretical return',
          'Consistency beats perfection in long-term investing',
        ],
      ),
      BookChapter(
        title: '8. Save Money',
        body:
            'Savings rate matters more than investment returns. You cannot '
            'control returns. You can control your savings rate. Wealth is '
            'the assets you accumulate, not the income you earn. '
            'Building savings doesn\'t require a reason — you don\'t need a '
            'specific goal. The value of savings is the options it creates '
            'in an unpredictable future.',
        keyPoints: [
          'Wealth is income minus spending — savings rate is the lever you control',
          'The value of savings is flexibility, not just future spending power',
          'Past a certain income level, lifestyle inflation is the enemy',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/0857197681',
  ),

  // ── The Intelligent Investor ───────────────────────────────────────────────
  BookInsightData(
    id: 'book_intelligent_investor',
    title: 'The Intelligent Investor',
    author: 'Benjamin Graham',
    tagline: "Warren Buffett's favourite book. The bible of value investing.",
    intro:
        'First published in 1949 and revised in 1973, Benjamin Graham\'s '
        'masterwork established the principles of value investing that have '
        'guided generations of the world\'s best investors. Warren Buffett '
        'called it "by far the best book on investing ever written." '
        'The central message: investing is not about market timing or '
        'speculation — it is about buying businesses at sensible prices '
        'and holding them with discipline.',
    chapters: [
      BookChapter(
        title: '1. Investment vs Speculation',
        body:
            'Graham\'s famous definition: "An investment operation is one '
            'which, upon thorough analysis, promises safety of principal and '
            'an adequate return. Operations not meeting these requirements are '
            'speculative." Most people calling themselves investors are '
            'speculators. Knowing the difference — and which one you are '
            'being — is the first step.',
        keyPoints: [
          'Investment = analysis + safety of principal + adequate return',
          'Speculation = hoping for price rises without fundamental analysis',
          'Even professionals often speculate while calling it investing',
        ],
      ),
      BookChapter(
        title: '2. Mr. Market',
        body:
            'Imagine a business partner named Mr. Market who shows up daily '
            'to offer to buy your share of the business or sell you his. '
            'Some days he\'s euphoric and quotes a high price. Other days '
            'he\'s depressed and quotes a low price. The intelligent investor '
            'uses Mr. Market\'s irrationality to their advantage — buying '
            'when he\'s depressed, ignoring him when he\'s manic.',
        keyPoints: [
          'The market is a voting machine short-term, a weighing machine long-term',
          'Market fluctuations are your servant, not your guide',
          'Buy more when prices fall; don\'t panic-sell',
        ],
      ),
      BookChapter(
        title: '3. Margin of Safety',
        body:
            'The three most important words in investing. Always buy at a '
            'significant discount to intrinsic value — the margin of safety '
            'absorbs errors of analysis and unexpected bad news. If a stock\'s '
            'intrinsic value is £100 and you pay £60, you have a £40 margin '
            'of safety. You can be wrong about the business and still make '
            'money. Pay full price and any mistake is catastrophic.',
        keyPoints: [
          'Always demand a discount to intrinsic value',
          'Margin of safety compensates for analysis errors and unpredictability',
          '"The secret of sound investment in three words: MARGIN OF SAFETY"',
        ],
      ),
      BookChapter(
        title: '4. Defensive vs Enterprising Investor',
        body:
            'Graham identifies two types: the Defensive Investor (passive, '
            'wants minimum effort and low risk) and the Enterprising Investor '
            '(active, willing to do significant work for above-average returns). '
            'Most people should be defensive investors. The defensive strategy: '
            'high-quality bonds + diversified common stocks held over long '
            'periods, rebalanced periodically. Index funds achieve this today.',
        keyPoints: [
          'Most people will get better results with a defensive, passive strategy',
          'Doing less, more patiently, beats active trading for most investors',
          'Know yourself: are you genuinely willing to do the work of an enterprising investor?',
        ],
      ),
      BookChapter(
        title: '5. Stock Selection for the Defensive Investor',
        body:
            'Graham\'s criteria for defensive stock selection: adequate size, '
            'strong financial condition (current ratio 2:1), earnings stability '
            '(no deficit in the last 10 years), dividend record (uninterrupted '
            'for 20 years), earnings growth (at least 1/3 over a decade), '
            'moderate P/E (under 15), moderate price-to-book (under 1.5). '
            'Few companies pass all criteria — that\'s the point.',
        keyPoints: [
          'Boring, profitable, unglamorous companies often make the best investments',
          'Consistent earnings over 10 years matters more than exciting recent growth',
          'Never pay more than 15x earnings or 1.5x book value',
        ],
      ),
      BookChapter(
        title: '6. Inflation and Portfolio Policy',
        body:
            'Inflation is the investor\'s hidden enemy. Bonds lose real value '
            'during inflation. Graham recommends a dynamic bond/stock split: '
            'never less than 25% in either. When stocks are expensive, hold '
            'more bonds. When stocks are cheap, hold more stocks. Simple '
            'rebalancing to maintain a 50/50 split forces you to sell high '
            'and buy low automatically.',
        keyPoints: [
          'A balanced 50/50 split, rebalanced annually, outperforms most active strategies',
          'Inflation destroys bond returns over time',
          'Rebalancing is a mechanical system that removes emotion from investing',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/0060555661',
  ),

  // ── Zero to One ───────────────────────────────────────────────────────────
  BookInsightData(
    id: 'book_zero_to_one',
    title: 'Zero to One',
    author: 'Peter Thiel',
    tagline: 'Contrarian truths about building the future from scratch.',
    intro:
        'Peter Thiel co-founded PayPal, made the first outside investment in '
        'Facebook, and built Palantir. In Zero to One, he distils his '
        'philosophy on startups, progress, and monopoly. His core thesis: '
        'going from 0 to 1 (creating something new) is far more valuable '
        'than going from 1 to n (copying what already exists). The world '
        'needs founders who dare to build genuinely new things.',
    chapters: [
      BookChapter(
        title: '1. The Challenge of the Future',
        body:
            'Thiel\'s contrarian interview question: "What important truth do '
            'very few people agree with you on?" Progress comes in two forms: '
            'horizontal (globalisation — copying what works) and vertical '
            '(technology — doing something truly new). Most progress today is '
            'horizontal. The future belongs to those who make vertical leaps.',
        keyPoints: [
          'Horizontal progress: going from 1 to n (copying)',
          'Vertical progress: going from 0 to 1 (inventing)',
          'Technology is the primary source of genuine new wealth',
        ],
      ),
      BookChapter(
        title: '2. Competition is for Losers',
        body:
            'Every business is successful to the extent it does something '
            'others cannot. Monopoly is the condition of every successful '
            'business. Google, in its core search business, has a monopoly. '
            'Restaurants in a city compete in a perfectly competitive market '
            'and earn near-zero profits. Aim to build a monopoly, not '
            'compete in a crowded space.',
        keyPoints: [
          'Competition destroys profits — monopoly preserves them',
          'Monopolies lie about their monopoly (Google calls itself a tech company)',
          'Competitive markets lie about their size to attract investment',
        ],
      ),
      BookChapter(
        title: '3. The Characteristics of Monopoly',
        body:
            'Great technology companies combine four things: proprietary '
            'technology (10x better than the nearest alternative), network '
            'effects (more valuable with more users), economies of scale, '
            'and strong branding. Start small and monopolise a niche before '
            'expanding. Amazon started with books. Facebook started with '
            'Harvard students. Dominate a small market first.',
        keyPoints: [
          'Your technology must be at least 10x better to create a new market',
          'Network effects are the most powerful moat in tech',
          'Start small, dominate completely, then expand',
        ],
      ),
      BookChapter(
        title: '4. The Secrets of the World',
        body:
            'Every great business is built around a secret — something '
            'important that most people don\'t see or believe. Airbnb\'s '
            'secret: people will rent rooms in strangers\' homes. Uber\'s '
            'secret: unlicensed drivers will give strangers a lift. Ask: '
            'what valuable company is nobody building? The answer lives '
            'in the gap between conventional wisdom and reality.',
        keyPoints: [
          'Every great company is built on a secret the world doesn\'t yet believe',
          'Secrets about nature (science) or secrets about people (behaviour)?',
          'The best secrets are found by thinking independently, not by consensus',
        ],
      ),
      BookChapter(
        title: '5. The Mechanics of Mafia',
        body:
            'The PayPal mafia (Musk, Hoffman, Levchin, Chen, etc.) went on '
            'to start or fund companies worth hundreds of billions. Why? '
            'They hired people who genuinely wanted to work with each other, '
            'not just people who wanted a job. Great founding teams are '
            'tribes with shared missions. Culture is not free lunches — '
            'it is the shared sense of purpose.',
        keyPoints: [
          'Hire people who are excited about the mission, not the perks',
          'A great team wins despite adversity; a poor culture collapses at the first setback',
          'Equity, not salary, aligns long-term interests in a startup',
        ],
      ),
      BookChapter(
        title: '6. The Founder\'s Paradox',
        body:
            'Founders are extreme individuals who create extreme companies. '
            'They are simultaneously insiders and outsiders. Great founders '
            'possess an unusual combination of contradictions: visionary yet '
            'grounded, demanding yet compassionate. The lesson for founders '
            'and investors alike: the value of a company comes from its '
            'long-term cash flows, and a great founder maximises the chance '
            'of reaching that future.',
        keyPoints: [
          'Founders need to be uniquely different to build something unique',
          'The last mover in a market wins, not the first mover',
          'Definite optimism (a clear plan for the future) outperforms indefinite drifting',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/0804139296',
  ),

  // ── \$100M Offers ─────────────────────────────────────────────────────────
  BookInsightData(
    id: 'book_100m_offers',
    title: r'$100M Offers',
    author: 'Alex Hormozi',
    tagline: 'How to make offers so good people feel stupid saying no.',
    intro:
        r'Alex Hormozi built four companies to over $1 million in revenue '
        r'by age 32 and currently oversees a portfolio doing over $200 million '
        'annually. This book distils the exact offer-creation system he used '
        'to go from broke to wealthy. The core insight: most businesses fail '
        'not because they lack skill or work ethic, but because they are '
        'selling the wrong offer at the wrong price to the wrong people.',
    chapters: [
      BookChapter(
        title: '1. Why Offers Matter',
        body:
            'Most entrepreneurs compete on price, which is a race to the '
            'bottom. The right offer lets you charge 10x–100x the competition '
            'and have customers thank you for it. A Grand Slam Offer is an '
            'offer you can present to your market that cannot be compared to '
            'any other product or service available. It makes price irrelevant.',
        keyPoints: [
          'Competing on price destroys margins and commoditises your business',
          'A Grand Slam Offer is so different it can\'t be compared',
          'Price is only an issue in the absence of value',
        ],
      ),
      BookChapter(
        title: '2. Finding the Right Market',
        body:
            'Four criteria for a great market: massive pain (the problem must '
            'be urgent and serious), purchasing power (they must be able to '
            'afford the solution), easy to target (you can reach them with '
            'ads or partnerships), and growing (a rising tide). The biggest '
            'mistake: solving a problem people have but don\'t care about '
            'enough to pay to fix.',
        keyPoints: [
          'Pain × Purchasing power × Accessibility × Growth = Market score',
          'Niche down until you can dominate before expanding',
          'Pick a hungry crowd before creating your product',
        ],
      ),
      BookChapter(
        title: '3. The Value Equation',
        body:
            'Hormozi\'s four-part value equation: (Dream Outcome × Perceived '
            'Likelihood of Achievement) ÷ (Time Delay × Effort and Sacrifice). '
            'To increase value: increase the dream outcome, increase the '
            'perceived probability of achieving it, decrease the time to '
            'results, and decrease the effort required. Most businesses only '
            'improve the top line; the fastest wins come from cutting the '
            'bottom line (time and effort).',
        keyPoints: [
          'Value = (Dream × Likelihood) ÷ (Time × Effort)',
          'Faster results with less effort increases perceived value dramatically',
          'Specificity increases perceived likelihood ("lose 21 lbs in 6 weeks" beats "lose weight")',
        ],
      ),
      BookChapter(
        title: '4. Creating the Offer',
        body:
            'Step 1: Identify the dream outcome. Step 2: List every obstacle '
            'between the customer and that outcome. Step 3: Turn each obstacle '
            'into a solution. Step 4: Package those solutions into deliverables. '
            'Step 5: Trim to what you can actually deliver and what has the '
            'highest value-to-cost ratio. The goal: solve every problem the '
            'customer could use to say no.',
        keyPoints: [
          'A premium offer eliminates every reason a prospect could say no',
          'Stack bonuses that cost you little but are highly valuable to the buyer',
          'Trim the offer to only the highest-leverage deliverables',
        ],
      ),
      BookChapter(
        title: '5. Pricing for Power',
        body:
            'Charge as much as you possibly can while keeping the customer '
            'feeling it is a bargain. Higher prices create higher perceived '
            'value, attract better clients, fund better delivery, and allow '
            r'a bigger marketing budget. Hormozi went from charging $600 '
            r'to $42,000 per client — and customer results improved because '
            'clients took it more seriously when they paid more.',
        keyPoints: [
          'Higher prices attract higher-quality clients who get better results',
          'Price is a proxy for quality in the absence of other information',
          'The goal is not to be the cheapest; it\'s to be worth the most',
        ],
      ),
      BookChapter(
        title: '6. Bonuses, Guarantees & Urgency',
        body:
            'Bonuses should be priced and presented individually before being '
            'bundled. Naming them matters — "The 30-Day Rapid Result '
            'Accelerator" beats "bonus 1." Guarantees invert the risk: you '
            'shoulder it so the buyer doesn\'t have to. Urgency and scarcity '
            '(real, not manufactured) are the strongest closes. A reason to '
            'act now is as important as the offer itself.',
        keyPoints: [
          'Name every bonus and give it a dollar value before bundling',
          'Guarantees remove risk from the buyer and signal your confidence',
          'Real scarcity (cohort size, your time) is always more powerful than fake urgency',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/B099QVG1H8',
  ),

  // ── Atomic Habits ─────────────────────────────────────────────────────────
  BookInsightData(
    id: 'book_atomic_habits',
    title: 'Atomic Habits',
    author: 'James Clear',
    tagline: 'Tiny changes, remarkable results. The 1% better every day framework.',
    intro:
        'James Clear broke his skull in a baseball accident at age 16, '
        'reconstructed his life through tiny habits, and went on to become '
        'a professional athlete and best-selling author. Atomic Habits — '
        'a #1 New York Times bestseller with over 15 million copies sold — '
        'argues that the quality of your life is a lagging measure of your '
        'habits. Small habits compound, just like money.',
    chapters: [
      BookChapter(
        title: '1. The Surprising Power of Tiny Habits',
        body:
            'If you get 1% better every day for a year, you\'ll end up 37x '
            'better. If you get 1% worse every day for a year, you\'ll decline '
            'to nearly zero. Habits are the compound interest of self-improvement. '
            'But the results don\'t show up immediately — the "Plateau of '
            'Latent Potential" makes habits feel ineffective until suddenly '
            'they break through.',
        keyPoints: [
          '1% better every day = 37x improvement in a year',
          'Results lag habits — keep going through the Plateau of Latent Potential',
          'Forget goals, focus on systems — goals are for direction, systems are for progress',
        ],
      ),
      BookChapter(
        title: '2. Identity-Based Habits',
        body:
            'The most effective way to change your habits is to focus not on '
            'what you want to achieve, but on who you wish to become. Every '
            'action is a vote for the type of person you want to be. The '
            'goal is not to run a marathon — it is to become a runner. '
            'Not to finish a book — but to become a reader. Identity change '
            'is the north star of habit change.',
        keyPoints: [
          'Outcomes-based: "I want to get fit." Identity-based: "I am someone who works out."',
          'Every habit is a vote for your identity',
          'Small habits are identity votes — cast enough and you believe it',
        ],
      ),
      BookChapter(
        title: '3. The Habit Loop (Cue–Craving–Response–Reward)',
        body:
            'All habits follow the same four-step loop: Cue (triggers the '
            'brain to begin the behaviour), Craving (the motivational force), '
            'Response (the actual habit), Reward (the end goal). To build a '
            'new habit: make the cue obvious, make the craving attractive, '
            'make the response easy, make the reward satisfying. To break a '
            'bad habit: invert each step.',
        keyPoints: [
          'Build: obvious cue + attractive craving + easy response + satisfying reward',
          'Break: invisible cue + unattractive craving + difficult response + unsatisfying reward',
          'Environment is the invisible hand that shapes behaviour',
        ],
      ),
      BookChapter(
        title: '4. Make It Obvious — Habit Stacking',
        body:
            'The most common cue is time + location. Redesign your environment '
            'to make cues for good habits obvious. Habit stacking: "After I '
            '[CURRENT HABIT], I will [NEW HABIT]." E.g. "After I pour my '
            'morning coffee, I will meditate for 1 minute." You are not just '
            'building a habit — you are connecting it to an existing behaviour.',
        keyPoints: [
          'Design your environment: put fruit on the counter, put the guitar in the way',
          'Habit stacking anchors new habits to existing routines',
          'Implementation intention: "I will [BEHAVIOUR] at [TIME] in [LOCATION]"',
        ],
      ),
      BookChapter(
        title: '5. Make It Easy — The Two-Minute Rule',
        body:
            'The two-minute rule: when starting a new habit, it should take '
            'less than two minutes to do. "Read 30 books a year" → "Read '
            'one page before bed." The point is not the two minutes — it is '
            'mastering the art of showing up. Once you start, it\'s easy to '
            'continue. Standardise before you optimise.',
        keyPoints: [
          'Make starting habits take less than 2 minutes',
          'The act of showing up is the foundation — optimise later',
          'Reduce friction for good habits; increase friction for bad ones',
        ],
      ),
      BookChapter(
        title: '6. The Role of Reward and Tracking',
        body:
            'Behaviours that are immediately rewarded are repeated. Behaviours '
            'that are immediately punished are avoided. The challenge: many '
            'good habits have delayed rewards (health, wealth) while bad habits '
            'have immediate rewards (junk food, Netflix). Habit tracking — '
            'crossing off a chain on a calendar — adds an immediate reward '
            'to any habit. Never miss twice: missing once is an accident; '
            'missing twice is the start of a new (bad) habit.',
        keyPoints: [
          'Add immediate rewards to habits with delayed payoffs',
          'Habit trackers provide visual proof of progress',
          'Never miss twice — one miss is an accident, two misses is a pattern',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/0735211299',
  ),

  // ── The Millionaire Next Door ──────────────────────────────────────────────
  BookInsightData(
    id: 'book_millionaire_next_door',
    title: 'The Millionaire Next Door',
    author: 'Thomas J. Stanley & William D. Danko',
    tagline: 'The surprising secrets of America\'s wealthy.',
    intro:
        'After 20 years of research into the wealthy, Stanley and Danko '
        'discovered that real millionaires look nothing like they do on TV. '
        'Most are first-generation wealthy, live in ordinary neighbourhoods, '
        r'drive used cars, and have never spent more than $400 on a suit. '
        'Their wealth comes not from high income but from systematic '
        'saving, frugal living, and disciplined investing.',
    chapters: [
      BookChapter(
        title: '1. Meet the Millionaire Next Door',
        body:
            'The typical American millionaire is 57, married, owns a '
            'business, lives in the same house for 20+ years, and drives '
            'a 3-year-old Ford. Two-thirds of the wealthy are self-employed. '
            'Most never received an inheritance. They became wealthy by '
            'living below their means and investing the difference, '
            'consistently, for decades.',
        keyPoints: [
          'Wealth is what you accumulate, not what you spend',
          'Most millionaires are self-employed business owners',
          'Wealth is built slowly through decades of disciplined saving',
        ],
      ),
      BookChapter(
        title: '2. Frugal, Frugal, Frugal',
        body:
            'The single biggest predictor of wealth is the ratio of wealth '
            'to income (the Wealth Accumulation Index). PAWs (Prodigious '
            'Accumulators of Wealth) live on less than half their income. '
            'UAWs (Under Accumulators of Wealth) spend everything they earn '
            r'and more. High income is not wealth. A surgeon earning $500k '
            r'who spends $480k is poorer than a plumber earning $80k '
            r'who saves and invests $40k.',
        keyPoints: [
          'Your wealth index = net worth ÷ (age × income ÷ 10)',
          'High income ≠ wealth; high savings rate = wealth',
          'Lifestyle inflation is the primary destroyer of high-earner wealth',
        ],
      ),
      BookChapter(
        title: '3. Time, Energy, Money',
        body:
            'Wealthy people spend significantly more time per month planning '
            'their investments than non-wealthy people of the same income. '
            'They also spend more time teaching their children about money '
            'and business. Non-wealthy high-earners spend their time '
            'consuming — buying luxury goods, eating at expensive restaurants, '
            'upgrading cars and houses.',
        keyPoints: [
          'Wealthy people treat financial planning as a serious time investment',
          'What you spend your free time on reflects your priorities',
          'Delayed gratification practiced over decades = financial independence',
        ],
      ),
      BookChapter(
        title: '4. You Are Not What You Drive',
        body:
            'The most popular car among American millionaires: used, domestic '
            'make. Only a minority of genuine millionaires ever buy a new '
            'luxury vehicle. The people who own the flashy luxury cars are '
            'mostly high earners who are not wealthy. Signalling wealth '
            'through consumption is the best way to stay not-wealthy.',
        keyPoints: [
          'Expensive cars are mostly owned by non-millionaires showing off',
          'Buy depreciating assets (cars, clothes) frugally',
          'Invest the difference between what you could spend and what you do spend',
        ],
      ),
      BookChapter(
        title: '5. Economic Outpatient Care',
        body:
            'Giving money to adult children typically weakens them financially. '
            'Adults who receive regular financial gifts from parents save '
            'far less themselves. They spend up to the level of their lifestyle '
            '(income + gifts) and never build the discipline to accumulate. '
            'Wealthy families teach children financial independence — they '
            'raise achievers, not dependants.',
        keyPoints: [
          'Regular financial gifts to adult children often harm their wealth-building',
          'Raise children to be financially independent, not financially dependent',
          'Teach work ethic and financial literacy early — before formal education',
        ],
      ),
    ],
    purchaseUrl: 'https://www.amazon.com/dp/1589795474',
  ),
];

/// Look up insights by book ID.
BookInsightData? findInsight(String bookId) {
  try {
    return kBookInsights.firstWhere((b) => b.id == bookId);
  } on StateError {
    return null;
  }
}
