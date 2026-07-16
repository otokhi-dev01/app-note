import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/features/notes/domain/entities/folder.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/usecases/create_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_folders_usecase.dart';

import '../home_style.dart';

part 'move_note_sheet.dart';
part 'recently_deleted_sheet.dart';
part 'share_bottom_sheet.dart';
