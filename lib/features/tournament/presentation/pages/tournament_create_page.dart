import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/tournament/data/models/team_model.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_cubit.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TournamentCreatePage extends StatefulWidget {
  const TournamentCreatePage({super.key});

  @override
  State<TournamentCreatePage> createState() => _TournamentCreatePageState();
}

class _TournamentCreatePageState extends State<TournamentCreatePage> {
  final _nameController = TextEditingController();
  TournamentFormat _selectedFormat = TournamentFormat.groupAndKnockout;
  bool _manualArrangement = false;
  final Map<String, List<String>> _manualGroups = {};
  final List<String> _selectedTeamIds = [];

  bool _manualKnockout = false;
  final List<List<String>> _manualKnockoutMatchups = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    context.read<TournamentCubit>().fetchTeams();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova Copa',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocConsumer<TournamentCubit, TournamentState>(
        listener: (context, state) {
          if (state is TournamentCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Copa criada com sucesso! 🏆'),
                  ],
                ),
                backgroundColor: HexColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            Navigator.pop(context);
          }
          if (state is TournamentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: HexColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TournamentLoading) {
            return const Center(
              child: CircularProgressIndicator(color: HexColors.primary),
            );
          }
          return Column(
            children: [
              // ── Stepper visual ──────────────────────────────────
              _HexStepper(currentStep: _currentStep),

              // ── Conteúdo do passo ───────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildStep(context),
                ),
              ),

              // ── Botões de navegação ─────────────────────────────
              _buildNavButtons(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2(context);
      case 2:
        return _buildStep3(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Passo 1: Configurar copa ──────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          icon: Icons.emoji_events_outlined,
          title: 'Configurar Copa',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome da Copa',
            prefixIcon: Icon(Icons.edit_outlined, color: HexColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'FORMATO',
          style: TextStyle(
            color: HexColors.textSubtle,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...TournamentFormat.values.map(
          (f) => GestureDetector(
            onTap: () => setState(() {
              _selectedFormat = f;
              _manualArrangement = false;
              _manualGroups.clear();
              _manualKnockout = false;
              _manualKnockoutMatchups.clear();
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedFormat == f
                    ? HexColors.cardHighlight
                    : HexColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFormat == f
                      ? HexColors.primary
                      : HexColors.border,
                  width: _selectedFormat == f ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedFormat == f
                            ? HexColors.primary
                            : HexColors.textSubtle,
                        width: 2,
                      ),
                    ),
                    child: _selectedFormat == f
                        ? Container(
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: HexColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      f.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedFormat == f
                            ? HexColors.primary
                            : HexColors.textMuted,
                      ),
                    ),
                  ),
                  if (_selectedFormat == f)
                    const Icon(
                      Icons.check_circle,
                      color: HexColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedFormat == TournamentFormat.groupAndKnockout ||
            _selectedFormat == TournamentFormat.directKnockout) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              if (_selectedFormat == TournamentFormat.groupAndKnockout) {
                _manualArrangement = !_manualArrangement;
                _manualGroups.clear();
              } else {
                _manualKnockout = !_manualKnockout;
                _manualKnockoutMatchups.clear();
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HexColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HexColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    (_selectedFormat == TournamentFormat.groupAndKnockout
                            ? _manualArrangement
                            : _manualKnockout)
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    color:
                        (_selectedFormat == TournamentFormat.groupAndKnockout
                            ? _manualArrangement
                            : _manualKnockout)
                        ? HexColors.primary
                        : HexColors.textSubtle,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFormat == TournamentFormat.groupAndKnockout
                              ? 'Arranjo manual dos grupos'
                              : 'Arranjo manual dos confrontos',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: HexColors.textPrimary,
                          ),
                        ),
                        Text(
                          _selectedFormat == TournamentFormat.groupAndKnockout
                              ? 'Escolha quais times ficam em cada grupo'
                              : 'Escolha quem joga contra quem no mata-mata',
                          style: const TextStyle(
                            color: HexColors.textSubtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Passo 2: Selecionar times ─────────────────────────────────────────────

  Widget _buildStep2(BuildContext context) {
    final allTeams = context.watch<TournamentCubit>().allTeamsFromDb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          icon: Icons.groups_outlined,
          title: 'Selecionar Times',
          subtitle: '${_selectedTeamIds.length} selecionados • mín. 4, máx. 32',
        ),
        const SizedBox(height: 20),
        if (allTeams.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HexColors.cardHighlight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HexColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: HexColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum time cadastrado. Vá em Gerenciamento para criar times.',
                    style: TextStyle(color: HexColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...allTeams.map((team) {
            final selected = _selectedTeamIds.contains(team.id);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedTeamIds.remove(team.id)
                    : _selectedTeamIds.add(team.id);
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? HexColors.cardHighlight
                      : HexColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? HexColors.primary : HexColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? HexColors.primary.withValues(alpha: 0.2)
                            : HexColors.cardHighlight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          team.name.isNotEmpty
                              ? team.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? HexColors.primary
                                : HexColors.textSubtle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        team.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? HexColors.primary
                              : HexColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: HexColors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Passo 3: Confirmar / Arranjo manual ───────────────────────────────────

  Widget _buildStep3(BuildContext context) {
    final allTeams = context.watch<TournamentCubit>().allTeamsFromDb;
    final selectedTeams = allTeams
        .where((t) => _selectedTeamIds.contains(t.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(icon: Icons.check_circle_outline, title: 'Confirmar'),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HexColors.cardHighlight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HexColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Nome',
                value: _nameController.text.isEmpty
                    ? 'Copa Hexagon'
                    : _nameController.text,
              ),
              const Divider(color: HexColors.border, height: 20),
              _SummaryRow(label: 'Formato', value: _selectedFormat.label),
              const Divider(color: HexColors.border, height: 20),
              _SummaryRow(
                label: 'Times',
                value: '${_selectedTeamIds.length} selecionados',
              ),
            ],
          ),
        ),

        if (_manualArrangement &&
            _selectedFormat == TournamentFormat.groupAndKnockout) ...[
          const SizedBox(height: 24),
          const Text(
            'DISTRIBUIÇÃO DOS GRUPOS',
            style: TextStyle(
              color: HexColors.textSubtle,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildManualGroups(context, selectedTeams, allTeams),
        ],

        if (_manualKnockout &&
            _selectedFormat == TournamentFormat.directKnockout) ...[
          const SizedBox(height: 24),
          const Text(
            'CONFRONTOS DO MATA-MATA',
            style: TextStyle(
              color: HexColors.textSubtle,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildManualKnockout(context, selectedTeams, allTeams),
        ],
      ],
    );
  }

  Widget _buildManualGroups(
    BuildContext context,
    List<Team> selectedTeams,
    List<Team> allTeams,
  ) {
    final numberOfGroups = _selectedTeamIds.length ~/ 4;
    for (int i = 0; i < numberOfGroups; i++) {
      final g = String.fromCharCode(65 + i);
      _manualGroups.putIfAbsent(g, () => []);
    }
    final validGroups = List.generate(
      numberOfGroups,
      (i) => String.fromCharCode(65 + i),
    );
    _manualGroups.removeWhere((k, _) => !validGroups.contains(k));

    final assignedIds = _manualGroups.values.expand((ids) => ids).toSet();
    final unassignedIds = _selectedTeamIds
        .where((id) => !assignedIds.contains(id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unassignedIds.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HexColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HexColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sem grupo (${unassignedIds.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: HexColors.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: unassignedIds.map((id) {
                    final team = allTeams.firstWhere((t) => t.id == id);
                    return GestureDetector(
                      onTap: () =>
                          _showGroupPicker(context, id, numberOfGroups),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: HexColors.cardHighlight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: HexColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                color: HexColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.add,
                              size: 14,
                              color: HexColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...validGroups.map((groupName) {
          final groupIds = _manualGroups[groupName] ?? [];
          final isFull = groupIds.length >= 4;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFull
                  ? HexColors.success.withValues(alpha: 0.08)
                  : HexColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFull ? HexColors.success : HexColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Grupo $groupName',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isFull
                            ? HexColors.success
                            : HexColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${groupIds.length}/4)',
                      style: TextStyle(
                        color: isFull
                            ? HexColors.success
                            : HexColors.textSubtle,
                        fontSize: 13,
                      ),
                    ),
                    if (isFull) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: HexColors.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                if (groupIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: groupIds.map((id) {
                      final team = allTeams.firstWhere((t) => t.id == id);
                      return GestureDetector(
                        onTap: () => setState(
                          () => _manualGroups[groupName]!.remove(id),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: HexColors.cardHighlight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: HexColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  color: HexColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.close,
                                size: 12,
                                color: HexColors.textSubtle,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Arranjo manual mata-mata ──────────────────────────────────────────────

  Widget _buildManualKnockout(
    BuildContext context,
    List<Team> selectedTeams,
    List<Team> allTeams,
  ) {
    final totalPairs = _selectedTeamIds.length ~/ 2;

    while (_manualKnockoutMatchups.length < totalPairs) {
      _manualKnockoutMatchups.add([]);
    }
    while (_manualKnockoutMatchups.length > totalPairs) {
      _manualKnockoutMatchups.removeLast();
    }

    final assignedIds = _manualKnockoutMatchups.expand((pair) => pair).toSet();
    final unassignedIds = _selectedTeamIds
        .where((id) => !assignedIds.contains(id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unassignedIds.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HexColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HexColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sem confronto (${unassignedIds.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: HexColors.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: unassignedIds.map((id) {
                    final team = allTeams.firstWhere((t) => t.id == id);
                    return GestureDetector(
                      onTap: () => _showMatchupPicker(context, id, totalPairs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: HexColors.cardHighlight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: HexColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                color: HexColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.add,
                              size: 14,
                              color: HexColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        ...List.generate(totalPairs, (i) {
          final pair = _manualKnockoutMatchups[i];
          final isFull = pair.length == 2;

          String homeName = '—';
          String awayName = '—';
          if (pair.isNotEmpty) {
            homeName = allTeams.firstWhere((t) => t.id == pair[0]).name;
          }
          if (pair.length >= 2) {
            awayName = allTeams.firstWhere((t) => t.id == pair[1]).name;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isFull
                  ? HexColors.success.withValues(alpha: 0.08)
                  : HexColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFull ? HexColors.success : HexColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFull
                        ? HexColors.success.withValues(alpha: 0.2)
                        : HexColors.cardHighlight,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isFull
                            ? HexColors.success
                            : HexColors.textSubtle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: pair.isNotEmpty
                        ? () => setState(
                            () => _manualKnockoutMatchups[i].removeAt(0),
                          )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: HexColors.cardHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HexColors.border),
                      ),
                      child: Text(
                        homeName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: pair.isNotEmpty
                              ? HexColors.textPrimary
                              : HexColors.textSubtle,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isFull ? HexColors.success : HexColors.textSubtle,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: pair.length >= 2
                        ? () => setState(
                            () => _manualKnockoutMatchups[i].removeAt(1),
                          )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: HexColors.cardHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HexColors.border),
                      ),
                      child: Text(
                        awayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: pair.length >= 2
                              ? HexColors.textPrimary
                              : HexColors.textSubtle,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFull) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    color: HexColors.success,
                    size: 18,
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showMatchupPicker(BuildContext context, String teamId, int totalPairs) {
    final available = <int>[];
    for (int i = 0; i < totalPairs; i++) {
      if (_manualKnockoutMatchups[i].length < 2) {
        available.add(i);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: HexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: HexColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Escolha o confronto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HexColors.textPrimary,
                ),
              ),
            ),
            ...available.map((idx) {
              final pair = _manualKnockoutMatchups[idx];
              final count = pair.length;
              final isFull = count >= 2;
              final allTeams = context.read<TournamentCubit>().allTeamsFromDb;
              String desc = 'Jogo ${idx + 1}';
              if (pair.isNotEmpty) {
                final first = allTeams.firstWhere((t) => t.id == pair[0]).name;
                desc = 'Jogo ${idx + 1} — $first vs ?';
              }
              return ListTile(
                leading: Icon(
                  isFull ? Icons.check_circle : Icons.sports_soccer,
                  color: isFull ? HexColors.success : HexColors.primary,
                ),
                title: Text(
                  desc,
                  style: TextStyle(
                    color: isFull
                        ? HexColors.textSubtle
                        : HexColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$count/2 times',
                  style: const TextStyle(
                    color: HexColors.textSubtle,
                    fontSize: 12,
                  ),
                ),
                enabled: !isFull,
                onTap: isFull
                    ? null
                    : () {
                        setState(
                          () => _manualKnockoutMatchups[idx].add(teamId),
                        );
                        Navigator.pop(ctx);
                      },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showGroupPicker(
    BuildContext context,
    String teamId,
    int numberOfGroups,
  ) {
    final options = List.generate(
      numberOfGroups,
      (i) => String.fromCharCode(65 + i),
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: HexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: HexColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Escolha o grupo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HexColors.textPrimary,
                ),
              ),
            ),
            ...options.map((groupName) {
              final count = (_manualGroups[groupName] ?? []).length;
              final isFull = count >= 4;
              return ListTile(
                leading: Icon(
                  isFull ? Icons.check_circle : Icons.circle_outlined,
                  color: isFull ? HexColors.success : HexColors.textSubtle,
                ),
                title: Text(
                  'Grupo $groupName ($count/4)',
                  style: TextStyle(
                    color: isFull
                        ? HexColors.textSubtle
                        : HexColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                enabled: !isFull,
                onTap: isFull
                    ? null
                    : () {
                        setState(() => _manualGroups[groupName]!.add(teamId));
                        Navigator.pop(ctx);
                      },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Botões de navegação ───────────────────────────────────────────────────

  Widget _buildNavButtons(BuildContext context, TournamentState state) {
    final isLast = _currentStep == 2;
    final canProceed = _currentStep == 0
        ? true
        : _currentStep == 1
        ? _selectedTeamIds.length >= 4
        : true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: HexColors.surface,
        border: Border(top: BorderSide(color: HexColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HexColors.textMuted,
                  side: const BorderSide(color: HexColors.border),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: canProceed
                  ? () {
                      if (!isLast) {
                        setState(() => _currentStep++);
                      } else {
                        _submit(context);
                      }
                    }
                  : null,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: canProceed
                      ? const LinearGradient(
                          colors: [HexColors.primary, HexColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: canProceed ? null : HexColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canProceed
                      ? [
                          BoxShadow(
                            color: HexColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Criar Copa 🏆' : 'Próximo →',
                    style: TextStyle(
                      color: canProceed ? Colors.white : HexColors.textSubtle,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_manualArrangement &&
        _selectedFormat == TournamentFormat.groupAndKnockout) {
      final assigned = _manualGroups.values.expand((ids) => ids).toSet();
      if (assigned.length != _selectedTeamIds.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coloque todos os times em um grupo!'),
            backgroundColor: HexColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      for (final entry in _manualGroups.entries) {
        if (entry.value.length != 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Grupo ${entry.key} precisa ter exatamente 4 times!',
              ),
              backgroundColor: HexColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      }
    }

    if (_manualKnockout && _selectedFormat == TournamentFormat.directKnockout) {
      final assignedKnockout = _manualKnockoutMatchups
          .expand((pair) => pair)
          .toSet();
      if (assignedKnockout.length != _selectedTeamIds.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coloque todos os times em um confronto!'),
            backgroundColor: HexColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      for (int i = 0; i < _manualKnockoutMatchups.length; i++) {
        if (_manualKnockoutMatchups[i].length != 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jogo ${i + 1} precisa ter exatamente 2 times!'),
              backgroundColor: HexColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      }
    }

    final allTeams = context.read<TournamentCubit>().allTeamsFromDb;
    final selectedTeams = _selectedTeamIds.map((id) {
      final team = allTeams.firstWhere((t) => t.id == id);
      return TeamModel(id: team.id, name: team.name);
    }).toList();

    context.read<TournamentCubit>().createTournament(
      name: _nameController.text.isEmpty
          ? 'Copa Hexagon'
          : _nameController.text,
      selectedTeams: selectedTeams,
      format: _selectedFormat,
      manualGroups: _manualArrangement ? _manualGroups : null,
      manualKnockoutMatchups: _manualKnockout ? _manualKnockoutMatchups : null,
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _HexStepper extends StatelessWidget {
  final int currentStep;
  const _HexStepper({required this.currentStep});

  static const _steps = ['Configurar', 'Times', 'Confirmar'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: HexColors.surface,
        border: Border(bottom: BorderSide(color: HexColors.border)),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isDone = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? HexColors.primary : HexColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = currentStep > stepIndex;
          final isActive = currentStep == stepIndex;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDone || isActive
                      ? const LinearGradient(
                          colors: [HexColors.primary, HexColors.primaryDark],
                        )
                      : null,
                  color: isDone || isActive ? null : HexColors.surfaceElevated,
                  border: Border.all(
                    color: isDone || isActive
                        ? HexColors.primary
                        : HexColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : HexColors.textSubtle,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? HexColors.primary : HexColors.textSubtle,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _StepTitle({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HexColors.cardHighlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: HexColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: HexColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  color: HexColors.textSubtle,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: HexColors.textSubtle, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: HexColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
