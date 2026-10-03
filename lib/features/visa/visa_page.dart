import 'package:flutter/material.dart';

import '../../app/travel_controller.dart';
import 'visa_plan.dart';
import 'visa_plan_editor.dart';

class VisaPage extends StatefulWidget {
  const VisaPage({super.key, required this.controller});

  final TravelController controller;

  @override
  State<VisaPage> createState() => _VisaPageState();
}

class _VisaPageState extends State<VisaPage> {
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save visa plan: $error')),
        );
      }
    }
  }

  Future<void> _addPlan() async {
    final plan = await showVisaPlanEditor(context);
    if (plan != null) await _run(() => widget.controller.addVisaPlan(plan));
  }

  Future<void> _editPlan(VisaPlan plan) async {
    final edited = await showVisaPlanEditor(context, plan: plan);
    if (edited != null) {
      await _run(() => widget.controller.updateVisaPlan(edited));
    }
  }

  Future<void> _deletePlan(VisaPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete visa block?'),
        content: Text('Remove ${plan.destination} and its checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.controller.deleteVisaPlan(plan.id));
    }
  }

  Future<String?> _askItemTitle({String? current}) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _ChecklistItemDialog(current: current),
    );
  }

  Future<void> _addItem(VisaPlan plan) async {
    final title = await _askItemTitle();
    if (title == null) return;
    await _run(
      () => widget.controller.updateVisaPlan(
        plan.withChecklist([
          ...plan.checklist,
          VisaChecklistItem.create(title),
        ]),
      ),
    );
  }

  Future<void> _editItem(VisaPlan plan, VisaChecklistItem item) async {
    final title = await _askItemTitle(current: item.title);
    if (title == null) return;
    await _run(
      () => widget.controller.updateVisaPlan(
        plan.withChecklist([
          for (final current in plan.checklist)
            if (current.id == item.id)
              current.copyWith(title: title)
            else
              current,
        ]),
      ),
    );
  }

  Future<void> _toggleItem(VisaPlan plan, VisaChecklistItem item, bool done) =>
      _run(
        () => widget.controller.updateVisaPlan(
          plan.withChecklist([
            for (final current in plan.checklist)
              if (current.id == item.id)
                current.copyWith(done: done)
              else
                current,
          ]),
        ),
      );

  Future<void> _deleteItem(VisaPlan plan, VisaChecklistItem item) => _run(
    () => widget.controller.updateVisaPlan(
      plan.withChecklist(
        plan.checklist.where((current) => current.id != item.id).toList(),
      ),
    ),
  );

  Widget _planCard(VisaPlan plan) {
    final done = plan.checklist.where((item) => item.done).length;
    final visaLabel = switch (plan.visaRequired) {
      true => 'Visa needed',
      false => 'No visa needed',
      null => 'Visa: not set',
    };
    final applicationLabel = switch (plan.applicationRequired) {
      true => 'Application needed',
      false => 'No application needed',
      null => 'Application: not set',
    };
    return Card(
      key: ValueKey('visa-plan-${plan.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey('visa-expansion-${plan.id}'),
        initiallyExpanded: true,
        leading: const Icon(Icons.description_outlined),
        title: Text(plan.destination),
        subtitle: Text('$done/${plan.checklist.length} checklist tasks done'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(visaLabel)),
                    Chip(label: Text(applicationLabel)),
                    if (plan.allowedStayDays != null)
                      Chip(
                        label: Text('Can stay ${plan.allowedStayDays} days'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Checklist',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (plan.checklist.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tasks yet. Add a step to prepare for this destination.',
                    ),
                  ),
                for (final item in plan.checklist)
                  Row(
                    key: ValueKey('visa-item-${item.id}'),
                    children: [
                      Checkbox(
                        value: item.done,
                        semanticLabel: item.done
                            ? 'Mark ${item.title} not done'
                            : 'Mark ${item.title} done',
                        onChanged: (value) =>
                            _toggleItem(plan, item, value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit ${item.title}',
                        onPressed: () => _editItem(plan, item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete ${item.title}',
                        onPressed: () => _deleteItem(plan, item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _addItem(plan),
                      icon: const Icon(Icons.add_task),
                      label: const Text('Add checklist item'),
                    ),
                    OutlinedButton(
                      onPressed: () => _editPlan(plan),
                      child: const Text('Edit info'),
                    ),
                    TextButton(
                      onPressed: () => _deletePlan(plan),
                      child: const Text('Delete block'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visa plans',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep entry details and preparation tasks by destination.',
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: _addPlan,
            icon: const Icon(Icons.add),
            label: const Text('Add visa block'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      if (widget.controller.visaPlans.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No visa blocks yet. Add a destination to start a checklist.',
            ),
          ),
        )
      else
        for (final plan in widget.controller.visaPlans) _planCard(plan),
    ],
  );
}

class _ChecklistItemDialog extends StatefulWidget {
  const _ChecklistItemDialog({this.current});

  final String? current;

  @override
  State<_ChecklistItemDialog> createState() => _ChecklistItemDialogState();
}

class _ChecklistItemDialogState extends State<_ChecklistItemDialog> {
  late final title = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'Add checklist item' : 'Edit item'),
    content: TextField(
      controller: title,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(labelText: 'Task'),
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: title,
        builder: (context, value, _) => FilledButton(
          onPressed: value.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, value.text.trim()),
          child: const Text('Save'),
        ),
      ),
    ],
  );
}
