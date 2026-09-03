import 'package:flutter/material.dart';

class TutorialDetourScreen extends StatelessWidget {

  const TutorialDetourScreen({super.key});

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0D0D0F),

      appBar: AppBar(

        backgroundColor: const Color(0xFF0D0D0F),

        foregroundColor: const Color(0xFFF5F2E8),

        title: const Text(

          'DETOUR',

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

                title: 'HOW DETOUR WORKS',

                body:
                    'Detour finds questionable stops along your road trip, based on your trip preferences and the route you’re taking.',

              ),

              _TutorialSection(

                number: '02',

                title: 'CHOOSE YOUR STARTING LOCATION AND DESTINATION',

                body:
                    'Your starting location is based on your current GPS location. Choose your destination to tell Detour where you’re headed.',

              ),

              _TutorialSection(

                number: '03',

                title: 'SET YOUR TRIP PREFERENCES',

                body:
                    'How far are you willing to detour off your road trip? Set a minimum Dining Unhinged rating, maximum number of stops, and whether you only want venues that are open right now. Already visited or saved a venue? Choose to avoid it. You can also set your route preference and preferred categories.',

              ),

              _TutorialSection(

                number: '04',

                title: 'PLAN YOUR DETOUR',

                body:
                    'Hit PLAN MY DETOUR to build your route. Your results will appear on the Google Map. Edit your route as needed by dragging and dropping venues to reorder them or deleting venues you don’t want to visit. When you’re happy with your changes, hit REBUILD ROUTE to update your route.',

              ),

              _TutorialSection(

                number: '05',

                title: 'SAVE OR START YOUR DETOUR',

                body:
                    'SAVE DETOUR lets you save your detour for later. START DETOUR immediately starts your trip.',

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

  const _TutorialSection({

    required this.number,

    required this.title,

    required this.body,

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
