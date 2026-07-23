// part of 'recently_deleted_folders_view.dart';
//
// class _RecentlyDeletedHeader extends GetView<RecentlyDeletedFoldersController> {
//   const _RecentlyDeletedHeader();
//
//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final ColorScheme colorScheme = theme.colorScheme;
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(8, 6, 10, 10),
//       child: Row(
//         children: <Widget>[
//           CupertinoButton(
//             padding: const EdgeInsets.all(8),
//             onPressed: () {
//               Get.back<void>();
//             },
//             child: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
//           ),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Text(
//                   'Recently Deleted',
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     color: colorScheme.onSurface,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: -0.4,
//                   ),
//                 ),
//                 Obx(() {
//                   final int count = controller.deletedFolderCount;
//
//                   return Text(
//                     '$count deleted ${count == 1 ? 'folder' : 'folders'}',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: colorScheme.onSurfaceVariant,
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//           Obx(
//             () => CupertinoButton(
//               padding: const EdgeInsets.all(10),
//               onPressed: controller.isRefreshing.value
//                   ? null
//                   : controller.refreshFolders,
//               child: controller.isRefreshing.value
//                   ? const CupertinoActivityIndicator()
//                   : Icon(CupertinoIcons.refresh, color: colorScheme.primary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
