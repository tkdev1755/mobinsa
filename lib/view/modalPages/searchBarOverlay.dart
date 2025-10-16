import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../model/Student.dart';

class StudentSearchBar extends StatefulWidget {
  final List<Student> students;
  final Function onSelect;
  const StudentSearchBar({super.key, required this.students, required this.onSelect});

  @override
  State<StudentSearchBar> createState() => _StudentSearchBarState();
}

class _StudentSearchBarState extends State<StudentSearchBar> {
  final TextEditingController _controller = TextEditingController();

  Future<List<Student>> _search(String query) async {
    if (query.isEmpty) return [];
    return widget.students.where((e) => e.name.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        child: TypeAheadField<Student>(
          suggestionsCallback: _search,
          builder: (context, controller, focusNode) {
            return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  labelText: 'Rechercher un étudiant',
                )
            );
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion.name),
            );
          },
          onSelected: (suggestion) {
            print("Selected student : $suggestion");
            int index = widget.students.indexOf(suggestion);
            print("Index of  this student is $suggestion");
            widget.onSelect(index);
            _controller.text = suggestion.name;
          },
          hideOnEmpty: true,
          hideOnLoading: true,
          hideOnError: true,
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
    );
  }
}
