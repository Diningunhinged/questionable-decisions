import 'package:flutter/material.dart';

class TutorialCrawlScreen extends StatelessWidget {

  const TutorialCrawlScreen({super.key});

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0D0D0F),

      appBar: AppBar(

        backgroundColor: const Color(0xFF0D0D0F),

        foregroundColor: const Color(0xFFF5F2E8),

        title: const Text(

          'CRAWL',

          style: TextStyle(

            fontWeight: FontWeight.w900,

            letterSpacing: 1.2,

          ),

        ),

      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: const [
              _TutorialSection(
                number: '01',
                title: 'HOW CRAWL WORKS',
                body:
                    'Crawl builds a walking route through a series of venues based on what you’re looking for, how far you’re willing to walk, and just how questionable you’re feeling.',
              ),
              _TutorialSection(
                number: '02',
                title: 'CHOOSE YOUR STARTING LOCATION',
                body:
                    'Every questionable decision needs a starting point. Use your GPS location, search for a location, or choose one directly on the map.',
              ),
              _TutorialSection(
                number: '03',
                title: 'SET YOUR PARAMETERS',
                body:
                    'How questionable is your crawl? What are we looking for? How far are we walking? Set your preferences and we’ll take it from there.',
              ),
              _TutorialSection(
                number: '04',
                title: 'CHOOSE YOUR CRAWL',
                body:
                    'Suffering from Decision Paralysis? Let us make the questionable decisions for you. Prefer to stay in control? Build your crawl manually.',
              ),
              _TutorialSection(
                number: '05',
                title: 'ADD YOUR VENUES',
                body:
                    'Add the venues you want to hit. Drag them to change the order, or tap the trash can when one doesn’t make the cut.',
              ),
              _TutorialSection(
                number: '06',
                title: 'SAVE IT OR START IT',
                body:
                    'Not crawling today? SAVE CRAWL lets you name your crawl and save it for a future date. Ready to make some questionable decisions? START CRAWL gets things moving immediately.',
                emphasizeSaveStart: true,
              ),
            ],

          ),

        ),

      ),

    );

  }

}

class _TutorialSection extends StatelessWidget {

  final String number;

  final String title;

  final String body;

  final bool emphasizeSaveStart;

  const _TutorialSection({

    required this.number,

    required this.title,

    required this.body,

    this.emphasizeSaveStart = false,

  });

  @override

  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: const Color(0xFF1C1C1E),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white10),

      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            width: 34,

            height: 34,

            alignment: Alignment.center,

            decoration: BoxDecoration(

              color: const Color(0xFFD4AF37),

              borderRadius: BorderRadius.circular(8),

            ),

            child: Text(

              number,

              style: const TextStyle(

                color: Color(0xFF0D0D0F),

                fontWeight: FontWeight.w900,

              ),

            ),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: const TextStyle(

                    color: Color(0xFFD4AF37),

                    fontSize: 13,

                    fontWeight: FontWeight.w900,

                    letterSpacing: 1.1,

                  ),

                ),

                const SizedBox(height: 8),

                if (emphasizeSaveStart)

                  RichText(

                    text: const TextSpan(

                      style: TextStyle(

                        color: Colors.white70,

                        fontSize: 15,

                        height: 1.45,

                      ),

                      children: [

                        TextSpan(text: 'Not crawling today? '),

                        TextSpan(

                          text: 'SAVE CRAWL',

                          style: TextStyle(fontWeight: FontWeight.w900),

                        ),

                        TextSpan(

                          text:

                              ' lets you name your crawl and save it for a future date. Ready to make some questionable decisions? ',

                        ),

                        TextSpan(

                          text: 'START CRAWL',

                          style: TextStyle(fontWeight: FontWeight.w900),

                        ),

                        TextSpan(text: ' gets things moving immediately.'),

                      ],

                    ),

                  )

                else

                  Text(

                    body,

                    style: const TextStyle(

                      color: Colors.white70,

                      fontSize: 15,

                      height: 1.45,

                    ),

                  ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}
