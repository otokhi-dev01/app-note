// part of 'recently_deleted_folders_view.dart';
//
// class _DeletedFolderCard extends StatelessWidget {
//   final FolderEntity folder;
//   final String deletedDateText;
//   final bool isRestoring;
//   final VoidCallback onRestore;
//
//   const _DeletedFolderCard({
//     super.key,
//     required this.folder,
//     required this.deletedDateText,
//     required this.isRestoring,
//     required this.onRestore,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final ColorScheme colorScheme = theme.colorScheme;
//     final bool isDark = theme.brightness == Brightness.dark;
//     final String folderName = folder.name.trim().isEmpty
//         ? 'Unnamed Folder'
//         : folder.name.trim();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1B1D22) : Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: colorScheme.outlineVariant.withValues(
//             alpha: isDark ? 0.18 : 0.35,
//           ),
//         ),
//         boxShadow: <BoxShadow>[
//           BoxShadow(
//             color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.045),
//             blurRadius: 22,
//             offset: const Offset(0, 9),
//           ),
//         ],
//       ),
//       child: Row(
//         children: <Widget>[
//           Container(
//             width: 54,
//             height: 54,
//             decoration: BoxDecoration(
//               color: colorScheme.error.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Icon(
//               CupertinoIcons.folder_fill,
//               size: 27,
//               color: colorScheme.error,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Text(
//                   folderName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.onSurface,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   '${folder.noteCount} ${folder.noteCount == 1 ? 'note' : 'notes'}',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   deletedDateText,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: colorScheme.error,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           CupertinoButton(
//             padding: EdgeInsets.zero,
//             onPressed: isRestoring ? null : onRestore,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 180),
//               height: 42,
//               padding: const EdgeInsets.symmetric(horizontal: 13),
//               decoration: BoxDecoration(
//                 color: colorScheme.primary.withValues(alpha: 0.11),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: colorScheme.primary.withValues(alpha: 0.20),
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   if (isRestoring)
//                     const CupertinoActivityIndicator()
//                   else ...<Widget>[
//                     Icon(
//                       CupertinoIcons.arrow_counterclockwise,
//                       size: 17,
//                       color: colorScheme.primary,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       'Restore',
//                       style: theme.textTheme.labelLarge?.copyWith(
//                         color: colorScheme.primary,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
