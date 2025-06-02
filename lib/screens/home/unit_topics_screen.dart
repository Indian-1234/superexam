import 'package:flutter/material.dart';

class UnitTopicsScreen extends StatefulWidget {
  final int initialExpandedUnit;

  const UnitTopicsScreen({
    Key? key,
    this.initialExpandedUnit = 1,
  }) : super(key: key);

  @override
  State<UnitTopicsScreen> createState() => _UnitTopicsScreenState();
}

class _UnitTopicsScreenState extends State<UnitTopicsScreen> {
  // Track which units are expanded
  late Map<int, bool> _expandedUnits = {
    1: false,  // Unit 1 is expanded by default
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
  };

  @override
  void initState() {
    super.initState();
    // Initialize with all units collapsed except the initialExpandedUnit
    _expandedUnits = {
      1: false,
      2: false,
      3: false,
      4: false,
      5: false,
      6: false,
    };
    // Set the initial unit as expanded
    _expandedUnits[widget.initialExpandedUnit] = true;
  }

  // Define the topics for each unit
  final Map<int, List<String>> _unitTopics = {
    1: ['01: Algae', '02: Fungi', '03: Lichen', '04: Bryophytes'],
    2: ['01: Pteridophytes', '02: Gymnosperms', '03: Angiosperms'],
    3: ['01: Algae', '02: Fungi', '03: Lichen', '04: Bryophytes'],
    4: ['01: Pteridophytes', '02: Gymnosperms', '03: Angiosperms'],
    5: ['01: Algae', '02: Fungi', '03: Lichen', '04: Bryophytes'],
    6: ['01: Pteridophytes', '02: Gymnosperms', '03: Angiosperms'],
  };

  // Define the unit descriptions
  final Map<int, String> _unitDescriptions = {
    1: 'Algae , Fungi,  Lichen',
    2: 'Pteridophytes, Gymnosperms and etc...',
    3: 'Algae, Fungi, Lichen and etc...',
    4: 'Pteridophytes, Gymnosperms and etc...',
    5: 'Algae, Fungi, Lichen and etc...',
    6: 'Pteridophytes, Gymnosperms and etc...',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Units & Topics',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: List.generate(6, (index) {
              final unitNumber = index + 1;
              return _buildUnitWidget(unitNumber);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitWidget(int unitNumber) {
    final isExpanded = _expandedUnits[unitNumber] ?? false;
    final topics = _unitTopics[unitNumber] ?? [];
    final description = _unitDescriptions[unitNumber] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Unit header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                // Toggle expansion state
                _expandedUnits[unitNumber] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF128831), // Green color
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8))
                    : BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit $unitNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (!isExpanded && description.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Topic:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Topics list (visible only when expanded)
          if (isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: index < topics.length - 1
                          ? BorderSide(color: Colors.grey.shade200)
                          : BorderSide.none,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      topics[index],
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      // Handle topic selection
                      _onTopicSelected(unitNumber, index);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _onTopicSelected(int unitNumber, int topicIndex) {
    final topic = _unitTopics[unitNumber]![topicIndex];

    // Navigate to exam screen using named route
    Navigator.pushNamed(
      context,
      '/exam',
      arguments: {
        'examTitle': 'Unit $unitNumber - $topic',
        'unitNumber': unitNumber,
        'topicIndex': topicIndex,
        'topic': topic,
      },
    );
  }
}