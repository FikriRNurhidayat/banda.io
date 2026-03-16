import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/features/accounts/providers/account_provider.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoanEditor extends StatefulWidget {
  final String? id;
  final bool readOnly;
  const LoanEditor({super.key, this.id, this.readOnly = false});

  @override
  State<LoanEditor> createState() => _LoanEditorState();
}

class _LoanEditorState extends State<LoanEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/loans/${widget.id!}/menu");
  }

  void handleSubmit() {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final loanProvider = context.read<LoanProvider>();

    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      Future(() async {
        if (widget.id == null) {
          await loanProvider.create(
            fee: _d["fee"],
            amount: _d["amount"],
            issuedAt: _d["issuedAt"].dateTime,
            settledAt: _d["settledAt"]?.dateTime,
            type: _d["type"],
            status: _d["status"],
            partyId: _d["partyId"],
            accountId: _d["accountId"],
          );
        }

        if (widget.id != null) {
          await loanProvider.update(
            widget.id!,
            fee: _d["fee"],
            amount: _d["amount"],
            issuedAt: _d["issuedAt"].dateTime,
            settledAt: _d["settledAt"]?.dateTime,
            type: _d["type"],
            status: _d["status"],
            partyId: _d["partyId"],
            accountId: _d["accountId"],
          );
        }
      }).then((_) => navigator.pop()).catchError((error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit loan details failed");
      });
    }
  }

  redirect(BuildContext context, String named) {
    _form.currentState!.save();
    Navigator.pushNamed(context, named);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loanProvider = context.watch<LoanProvider>();
    final partyProvider = context.watch<PartyProvider>();
    final accountProvider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !widget.readOnly ? "Enter loan details" : "Loan details",
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmit();
                },
                icon: Icon(Icons.check),
              ),
            ),
          if (widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleMoreTap(context);
                },
                icon: Icon(Icons.more_horiz),
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
              partyProvider.search(),
              accountProvider.search(),
              if (widget.id != null) loanProvider.get(widget.id!),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final parties = snapshot.data![0] as List<Party>;
              final accounts = snapshot.data![1] as List<Account>;
              final loan = widget.id != null
                  ? (snapshot.data![2] as Loan)
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue: _d["amount"] ?? loan?.amount,
                      decoration: InputStyles.field(
                        hintText: "Enter amount...",
                        labelText: "Amount",
                      ),
                      onSaved: (value) => _d["amount"] = value,
                      validator: (value) =>
                          value == null ? "Amount is required" : null,
                    ),
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue: _d["fee"] ?? loan?.fee,
                      decoration: InputStyles.field(
                        hintText: "Enter fee...",
                        labelText: "Fee",
                      ),
                      onSaved: (value) => _d["fee"] = value,
                    ),
                    SelectFormField<LoanType>(
                      readOnly: widget.readOnly,
                      onSaved: (value) => _d["type"] = value,
                      initialValue:
                          _d["type"] ??
                          loan?.type ??
                          LoanType.receiveable,
                      validator: (value) =>
                          value == null ? "Type is required" : null,
                      options: LoanType.values.map((v) {
                        return SelectItem(value: v, label: v.label);
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Type",
                        hintText: "Select loan type...",
                      ),
                    ),
                    SelectFormField<LoanStatus>(
                      readOnly: widget.readOnly,
                      onSaved: (value) => _d["status"] = value,
                      initialValue:
                          _d["status"] ??
                          loan?.status ??
                          LoanStatus.active,
                      validator: (value) =>
                          value == null ? "Status is required" : null,
                      options: LoanStatus.values.map((v) {
                        return SelectItem(value: v, label: v.label);
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status type...",
                      ),
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: [
                        WhenOption.now,
                        WhenOption.specificTime,
                      ],
                      decoration: InputStyles.field(
                        labelText: "Issue",
                        hintText: "Select issue date & time...",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select issue date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select issue time...",
                      ),
                      initialValue:
                          _d["issuedAt"] ??
                          (loan?.issuedAt != null
                              ? When.specificTime(loan!.issuedAt)
                              : When.now()),
                      onSaved: (value) => _d["issuedAt"] = value,
                      validator: (value) => value == null
                          ? "Issue date & time is required"
                          : null,
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: [
                        WhenOption.now,
                        WhenOption.specificTime,
                        WhenOption.whenever,
                      ],
                      decoration: InputStyles.field(
                        labelText: "Settle",
                        hintText: "Select settle date & time...",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select settle date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select settle time...",
                      ),
                      initialValue:
                          _d["settledAt"] ??
                          (loan?.settledAt != null
                              ? When.specificTime(loan!.settledAt!)
                              : When.whenever()),
                      onSaved: (value) => _d["settledAt"] = value,
                      validator: (value) => value == null
                          ? "Settle date & time is required"
                          : null,
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue: _d["accountId"] ?? loan?.accountId,
                      onSaved: (value) => _d["accountId"] = value,
                      validator: (value) =>
                          value == null ? "Account is required" : null,
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New account",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect(context, "/accounts/new");
                            },
                          ),
                      ],
                      options: accounts.map((account) {
                        return SelectItem(
                          value: account.id,
                          label: account.displayName(),
                        );
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Account",
                        hintText: "Select account...",
                      ),
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue: _d["partyId"] ?? loan?.partyId,
                      onSaved: (value) => _d["partyId"] = value,
                      validator: (value) =>
                          value == null ? "Party is required" : null,
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New party",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect(context, "/parties/edit");
                            },
                          ),
                      ],
                      options: parties.map((party) {
                        return SelectItem(
                          value: party.id,
                          label: party.name,
                        );
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Party",
                        hintText: "Select party...",
                      ),
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
