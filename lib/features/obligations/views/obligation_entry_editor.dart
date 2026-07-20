import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_payment_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ObligationEntryEditor extends StatefulWidget {
  final String obligationId;
  final String? entryId;
  final bool readOnly;

  const ObligationEntryEditor({
    super.key,
    required this.obligationId,
    this.entryId,
    this.readOnly = false,
  });

  @override
  State<ObligationEntryEditor> createState() =>
      ObligationEntryEditorState();
}

class ObligationEntryEditorState extends State<ObligationEntryEditor> {
  final form = GlobalKey<FormState>();
  final FormData d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(
      context,
      "/obligations/${widget.obligationId}/payments/${widget.entryId!}/menu",
    );
  }

  void handleSubmit(BuildContext context) async {
    form.currentState!.save();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final obligationPaymentProvider = context
        .read<ObligationPaymentProvider>();

    if (form.currentState!.validate()) {
      try {
        if (isNull(widget.entryId)) {
          await obligationPaymentProvider.create(
            widget.obligationId,
            amount: d["amount"],
            fee: d["fee"],
            journalId: d["journalId"],
            issuedAt: d["issuedAt"]?.dateTime,
          );
        }

        if (!isNull(widget.entryId)) {
          await obligationPaymentProvider.update(
            widget.obligationId,
            widget.entryId!,
            amount: d["amount"],
            fee: d["fee"],
            journalId: d["journalId"],
            issuedAt: d["issuedAt"]?.dateTime,
          );
        }

        navigator.pop();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit obligation payment details failed!");
      }
    }
  }

  redirect(String routeName) {
    form.currentState!.save();
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.watch<JournalProvider>();
    final obligationProvider = context.watch<ObligationProvider>();
    final obligationPaymentProvider = context
        .watch<ObligationPaymentProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          widget.readOnly ? "Payment details" : "Edit payment details",
          style: theme.textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmit(context);
                },
                icon: Icon(Icons.check),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              journalProvider.search(),
              obligationProvider.get(widget.obligationId),
              if (widget.entryId != null)
                obligationPaymentProvider.get(
                  widget.obligationId,
                  widget.entryId!,
                ),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("..."));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final journals = snapshot.data![0] as List<Journal>;
              final ObligationPayment? payment = !isNull(widget.entryId)
                  ? snapshot.data![2] as ObligationPayment
                  : null;

              return Form(
                key: form,
                child: Column(
                  spacing: 16,
                  children: [
                    AmountFormField(
                      readOnly: widget.readOnly,
                      decoration: InputStyles.field(
                        labelText: "Amount",
                        hintText: "Enter amount...",
                      ),
                      initialValue:
                          d["amount"]?.abs() ?? payment?.amount,
                      onSaved: (value) => d["amount"] = value,
                      validator: (value) =>
                          value == null ? "Enter amount" : null,
                    ),
                    if (!isNull(payment?.fee) || !widget.readOnly)
                      AmountFormField(
                        readOnly: widget.readOnly,
                        decoration: InputStyles.field(
                          labelText: "Fee",
                          hintText: "Enter fee...",
                        ),
                        initialValue: d["fee"]?.abs() ?? payment?.fee,
                        onSaved: (value) => d["fee"] = value,
                      ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: WhenOption.min,
                      initialValue:
                          d["issuedAt"] ??
                          When.specificTime(payment?.issuedAt),
                      onSaved: (value) => d["issuedAt"] = value,
                      validator: (value) => value == null
                          ? "Date & time are required"
                          : null,
                      decoration: InputStyles.field(
                        hintText: "Select date & time...",
                        labelText: "Date & Time",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select time...",
                      ),
                    ),
                    SelectFormField(
                      readOnly: widget.readOnly,
                      decoration: InputStyles.field(
                        labelText: "Journal",
                        hintText: "Select journal...",
                      ),
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New journal",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect("/journals/new");
                            },
                          ),
                      ],
                      options: journals.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: "${i.name} — ${i.holderName}",
                        );
                      }).toList(),
                      initialValue:
                          d["journalId"] ?? payment?.entry.journalId,
                      onSaved: (value) => d["journalId"] = value,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
