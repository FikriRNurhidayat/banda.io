import 'package:bandha/features/tags/entities/tagable.dart';
import 'package:bandha/features/tags/providers/tagable_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagableSelector<I extends Tagable, P extends TagableProvider<I>>
    extends StatefulWidget {
  final String title;
  final String deletePromptText;
  final String deletePromptTitle;
  final String hintText;
  final IconData? tileIcon;

  const TagableSelector({
    super.key,
    required this.title,
    required this.deletePromptText,
    required this.deletePromptTitle,
    required this.hintText,
    this.tileIcon = Icons.label,
  });

  @override
  State<StatefulWidget> createState() => _TagableSelectorState<I, P>();
}

class _TagableSelectorState<
  I extends Tagable,
  P extends TagableProvider<I>
>
    extends State<TagableSelector> {
  String? editId;

  final _createFormKey = GlobalKey<FormState>();

  final _createController = TextEditingController();
  final _createFocus = FocusNode();
  final _editController = TextEditingController();
  final _editFocus = FocusNode();

  void _initCreate() {
    _editFocus.unfocus();
    _createFocus.requestFocus();

    setState(() {});
  }

  void _initEdit(I item) {
    _createFocus.unfocus();
    _editFocus.requestFocus();

    setState(() {
      editId = item.id;
      _editController.text = item.name;
    });
  }

  @override
  void dispose() {
    _createController.dispose();
    _createFocus.dispose();
    super.dispose();
  }

  void _create() {
    final value = _createController.text.trim();
    if (value.isNotEmpty) {
      context.read<P>().add(name: value);
      _createController.clear();
      _createFocus.unfocus();
      setState(() {});
    }
  }

  void _edit(I item) {
    final name = _editController.text.trim();
    if (name.isNotEmpty) {
      context.read<P>().update(id: item.id, name: name);
      setState(() => editId = null);
    }
  }

  void _delete(I item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.deletePromptTitle),
          content: Text(widget.deletePromptText),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                context.read<P>().remove(item.id);
                setState(() => editId = null);

                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemableProvider = context.watch<P>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleMedium),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<I>>(
        future: itemableProvider.search(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: const CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return ListView(
            children: [
              ListTile(
                leading: Icon(Icons.add),
                title: TextField(
                  key: _createFormKey,
                  onTap: _initCreate,
                  focusNode: _createFocus,
                  controller: _createController,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                  ),
                ),
                trailing: _createFocus.hasFocus
                    ? GestureDetector(
                        onTap: _create,
                        child: Icon(Icons.check),
                      )
                    : null,
              ),
              ...items.where((i) => !i.readOnly!).map((item) {
                final isEditing = item.id == editId;

                return ListTile(
                  leading: isEditing
                      ? GestureDetector(
                          child: Icon(Icons.delete),
                          onTap: () => _delete(item),
                        )
                      : Icon(widget.tileIcon),
                  title: isEditing
                      ? TextField(
                          key: ValueKey(item.id),
                          decoration: null,
                          focusNode: _editFocus,
                          controller: _editController,
                          keyboardType: TextInputType.text,
                        )
                      : Text(item.name),
                  trailing: isEditing
                      ? IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () => _edit(item),
                        )
                      : IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _initEdit(item),
                        ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
