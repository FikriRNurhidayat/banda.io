import 'package:flutter/material.dart';

class Verdict extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function(BuildContext context) onConfirm;
  final Future<void> Function(BuildContext context) onDeny;

  const Verdict({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final width = MediaQuery.of(context).size.width;
    final maxWidth = 768.0;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: (width * 0.5).clamp(0, maxWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                content,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.justify,
              ),
              Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      onDeny(context)
                          .then((_) {
                            navigator.pop(false);
                          })
                          .catchError((_) {
                            navigator.pop(false);
                          });
                    },
                    child: Text("No", style: theme.textTheme.bodySmall),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onConfirm(context)
                          .then((_) {
                            navigator.pop(true);
                          })
                          .catchError((_) {
                            navigator.pop(false);
                          });
                    },
                    child: Text(
                      "Yes",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
