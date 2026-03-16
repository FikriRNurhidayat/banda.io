import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/loans/entities/loan_payment.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/loans/providers/loan_payment_provider.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoanEntryEditor extends StatefulWidget {
  final String loanId;
  final String? entryId;
  final bool readOnly;

  const LoanEntryEditor({
    super.key,
    required this.loanId,
    this.entryId,
    this.readOnly = false,
  });

  @override
  State<LoanEntryEditor> createState() => LoanEntryEditorState();
}

class LoanEntryEditorState extends State<LoanEntryEditor> {
  final form = GlobalKey<FormState>();
  final FormData d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(
      context,
      "/loans/${widget.loanId}/payments/${widget.entryId!}/menu",
    );
  }

  void handleSubmit(BuildContext context) async {
    form.currentState!.save();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final loanPaymentProvider = context.read<LoanPaymentProvider>();

    if (form.currentState!.validate()) {
      try {
        if (isNull(widget.entryId)) {
          await loanPaymentProvider.create(
            widget.loanId,
            amount: d["amount"],
            fee: d["fee"],
            vaultId: d["vaultId"],
            issuedAt: d["issuedAt"]?.dateTime,
          );
        }

        if (!isNull(widget.entryId)) {
          await loanPaymentProvider.update(
            widget.loanId,
            widget.entryId!,
            amount: d["amount"],
            fee: d["fee"],
            vaultId: d["vaultId"],
            issuedAt: d["issuedAt"]?.dateTime,
          );
        }

        navigator.pop();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit loan payment details failed!");
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
    final vaultProvider = context.watch<VaultProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final loanPaymentProvider = context.watch<LoanPaymentProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.readOnly ? "Payment details" : "Edit payment details",
          style: theme.textTheme.titleLarge,
        ),
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
              vaultProvider.search(),
              loanProvider.get(widget.loanId),
              if (widget.entryId != null)
                loanPaymentProvider.get(widget.loanId, widget.entryId!),
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

              final vaults = snapshot.data![0] as List<Vault>;
              final LoanPayment? payment = !isNull(widget.entryId)
                  ? snapshot.data![2] as LoanPayment
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
                        labelText: "Vault",
                        hintText: "Select vault...",
                      ),
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New vault",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect("/vaults/new");
                            },
                          ),
                      ],
                      options: vaults.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: "${i.name} — ${i.holderName}",
                        );
                      }).toList(),
                      initialValue:
                          d["vaultId"] ?? payment?.entry.vaultId,
                      onSaved: (value) => d["vaultId"] = value,
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
