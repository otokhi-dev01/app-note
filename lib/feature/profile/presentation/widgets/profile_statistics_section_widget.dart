import 'package:flutter/cupertino.dart';

import 'profile_statistic_card_widget.dart';

class ProfileStatisticsSectionWidget extends StatelessWidget {
  const ProfileStatisticsSectionWidget({
    super.key,
    required this.folderCount,
    required this.noteCount,
  });

  final int folderCount;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ProfileStatisticCardWidget(
            icon: CupertinoIcons.folder_fill,
            label: folderCount == 1 ? 'Folder' : 'Folders',
            value: folderCount.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ProfileStatisticCardWidget(
            icon: CupertinoIcons.doc_text_fill,
            label: noteCount == 1 ? 'Note' : 'Notes',
            value: noteCount.toString(),
          ),
        ),
      ],
    );
  }
}
