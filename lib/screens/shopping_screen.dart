import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  Future<List<Map<String, dynamic>>> _lists = Future.value([]);

  @override
  void initState() {
    super.initState();
    _load();
    _tabs.addListener(_load);
  }

  void _load() {
    final lists = _db.getShoppingLists(history: _tabs.index == 1);
    if (!mounted) {
      _lists = lists;
      return;
    }
    setState(() {
      _lists = lists;
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_load);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final input = await showDialog<_ListInput>(
      context: context,
      builder: (_) => const _ListDialog(),
    );
    if (input != null) {
      final id = await _db.createShoppingList(
        input.name,
        store: input.store,
        budget: input.budget,
        shoppingDate: input.date,
        notes: input.notes,
      );
      if (mounted) await _openList(id);
    }
  }

  Future<void> _openList(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShoppingListEditor(listId: id)),
    );
    if (mounted) _load();
  }

  String _money(num value) => appCurrencyController.format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        foregroundColor: const Color(0xFF102A43),
        title: const Text(
          'Mis compras',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF0C2340),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF0C2340),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Actuales'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) {
            return _EmptyShoppingState(
              history: _tabs.index == 1,
              onCreate: _create,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: lists.length,
            itemBuilder: (_, index) {
              final list = lists[index];
              return _ShoppingListCard(
                list: list,
                money: _money,
                onTap: () => _openList(list['id'] as int),
                onDelete: () => _deleteList(list),
              );
            },
          );
        },
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nueva lista'),
              backgroundColor: const Color(0xFF0C2340),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _deleteList(Map<String, dynamic> list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _MovaDialog(
        icon: Icons.delete_sweep_outlined,
        title: 'Eliminar lista',
        subtitle: 'Se eliminarán también sus productos.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ],
        child: Text(
          '¿Quieres eliminar "${list['name']}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
      ),
    );
    if (confirmed != true) return;
    await _db.deleteShoppingList(list['id'] as int);
    if (mounted) _load();
  }
}

class _EmptyShoppingState extends StatelessWidget {
  final bool history;
  final VoidCallback onCreate;

  const _EmptyShoppingState({required this.history, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD7EEEA)),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 48,
                color: Color(0xFF0C2340),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              history
                  ? 'Aún no hay compras finalizadas'
                  : 'Planea tu primera compra',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              history
                  ? 'Cuando finalices una lista aparecerá aquí.'
                  : 'Organiza tus productos y controla cuánto vas a gastar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
            if (!history) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear lista'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0C2340),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  final Map<String, dynamic> list;
  final String Function(num) money;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ShoppingListCard({
    required this.list,
    required this.money,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = list['status'] == 'completed';
    final budget = (list['budget'] as num?)?.toDouble();
    final total = (list['total'] as num?)?.toDouble() ?? 0;
    final store = (list['store'] as String?)?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: completed
                            ? const [Color(0xFFE8F5E9), Color(0xFFE8F4FA)]
                            : const [Color(0xFFEAF6FA), Color(0xFFE8F4FA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      completed
                          ? Icons.task_alt_rounded
                          : Icons.shopping_basket_outlined,
                      color: completed
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102A43),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          store.isEmpty
                              ? (completed
                                    ? 'Compra finalizada'
                                    : 'Lista en curso')
                              : store,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Eliminar lista',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: const Color(0xFFB42318),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      money(total),
                      style: const TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (budget != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Presupuesto ${money(budget)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingSummaryCard extends StatelessWidget {
  final Map<String, dynamic> list;
  final String Function(num) money;
  final bool completed;

  const _ShoppingSummaryCard({
    required this.list,
    required this.money,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = (list['total'] as num?)?.toDouble() ?? 0;
    final budget = (list['budget'] as num?)?.toDouble();
    final difference = budget == null ? null : budget - total;
    final store = (list['store'] as String?)?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF0C2340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220C2340),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  completed ? 'Compra finalizada' : 'Control de compra',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (completed)
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFC7EAF4),
                  size: 21,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  money(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (budget != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Presupuesto',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      money(budget),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  difference! >= 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: difference >= 0
                      ? const Color(0xFFC7EAF4)
                      : const Color(0xFFFFD0C7),
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  difference >= 0
                      ? 'Disponible: ${money(difference)}'
                      : 'Sobre el presupuesto: ${money(difference.abs())}',
                  style: TextStyle(
                    color: difference >= 0
                        ? const Color(0xFFC7EAF4)
                        : const Color(0xFFFFD0C7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (store.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white70,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  store,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShoppingProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool completed;
  final String Function(num) money;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onPurchasedChanged;

  const _ShoppingProductCard({
    required this.product,
    required this.completed,
    required this.money,
    required this.onEdit,
    required this.onDelete,
    required this.onPurchasedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final price = (product['unit_price'] as num?)?.toDouble() ?? 0;
    final subtotal = (product['subtotal'] as num?)?.toDouble() ?? 0;
    final priceUnit =
        product['price_unit'] as String? ?? product['unit'] as String;
    final note = (product['note'] as String?)?.trim() ?? '';
    final pending = price <= 0;
    final purchased = (product['is_purchased'] as num?)?.toInt() == 1;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pending ? const Color(0xFFF3D7A4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: purchased,
            onChanged: completed
                ? null
                : (value) => onPurchasedChanged(value ?? false),
            activeColor: const Color(0xFF0C2340),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pending
                  ? const Color(0xFFFFF7E8)
                  : const Color(0xFFEAF6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              pending
                  ? Icons.help_outline_rounded
                  : Icons.shopping_basket_outlined,
              color: pending
                  ? const Color(0xFFB7791F)
                  : const Color(0xFF0C2340),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                    decoration: purchased
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product['quantity']} ${product['unit']}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  purchased ? 'Agregado al carrito' : 'Pendiente por comprar',
                  style: TextStyle(
                    color: purchased
                        ? const Color(0xFF0C2340)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pending ? 'Precio pendiente' : money(subtotal),
                style: TextStyle(
                  color: pending
                      ? const Color(0xFFB7791F)
                      : const Color(0xFF1E3A5F),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!pending)
                Text(
                  '${money(price)} / $priceUnit',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                ),
              if (!completed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Eliminar',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: const Color(0xFFB42318),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShoppingListEditor extends StatefulWidget {
  final int listId;
  const ShoppingListEditor({super.key, required this.listId});

  @override
  State<ShoppingListEditor> createState() => _ShoppingListEditorState();
}

class _ShoppingListEditorState extends State<ShoppingListEditor> {
  final _db = DatabaseHelper();
  late Future<Map<String, dynamic>?> _list;
  late Future<List<Map<String, dynamic>>> _products;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _list = _db.getShoppingList(widget.listId);
    _products = _db.getShoppingProducts(widget.listId);
  }

  Future<void> _addProduct([Map<String, dynamic>? product]) async {
    final result = await showDialog<_ProductInput>(
      context: context,
      builder: (_) => _ProductDialog(product: product),
    );
    if (result != null) {
      if (product == null) {
        await _db.addShoppingProduct(
          listId: widget.listId,
          name: result.name,
          unit: result.unit,
          quantity: result.quantity,
          unitPrice: result.price,
          priceUnit: result.priceUnit,
          note: result.note,
        );
      } else {
        await _db.updateShoppingProduct(
          id: product['id'] as int,
          name: result.name,
          unit: result.unit,
          quantity: result.quantity,
          unitPrice: result.price,
          priceUnit: result.priceUnit,
          note: result.note,
        );
      }
      if (mounted) setState(_refresh);
    }
  }

  Future<void> _finalize(Map<String, dynamic> list) async {
    if (_finishing) return;
    final total = (list['total'] as num).toDouble();
    if (total <= 0) {
      await showMovaError(
        context,
        'Agrega al menos un producto antes de finalizar.',
        title: 'Compra incompleta',
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _MovaDialog(
        icon: Icons.receipt_long_rounded,
        title: 'Registrar compra',
        subtitle: 'Esta acción no se puede deshacer.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Registrar gasto'),
          ),
        ],
        child: Text(
          'Se registrará un gasto de ${appCurrencyController.format(total)} en la categoría Compras.',
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
      ),
    );
    if (confirm == true) {
      setState(() => _finishing = true);
      try {
        await _db.finalizeShoppingList(widget.listId);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _finishing = false);
      }
    }
  }

  String _money(num value) => appCurrencyController.format(value);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _list,
      builder: (context, snapshot) {
        final list = snapshot.data;
        if (list == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final completed = list['status'] == 'completed';
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            foregroundColor: const Color(0xFF102A43),
            title: Text(
              list['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              if (!completed)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar nombre',
                  onPressed: () async {
                    final name = await showDialog<String>(
                      context: context,
                      builder: (_) =>
                          _RenameDialog(initial: list['name'] as String),
                    );
                    if (name != null && name.trim().isNotEmpty) {
                      await _db.updateShoppingListName(widget.listId, name);
                      if (mounted) setState(_refresh);
                    }
                  },
                ),
            ],
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _products,
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              return Column(
                children: [
                  _ShoppingSummaryCard(
                    list: list,
                    money: _money,
                    completed: completed,
                  ),
                  if (!completed)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 19,
                            color: Color(0xFF0C2340),
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Marca cada producto conforme lo agregues al carrito. Edita cantidad y precio en cualquier momento.',
                              style: TextStyle(
                                color: Color(0xFF1E3A5F),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF6FA),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.playlist_add_rounded,
                                      size: 36,
                                      color: Color(0xFF0C2340),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Tu lista está vacía',
                                    style: TextStyle(
                                      color: Color(0xFF102A43),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Agrega productos para calcular tu compra.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                    onPressed: () => _addProduct(),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Agregar producto'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0C2340),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: products.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = products[i];
                              return _ShoppingProductCard(
                                product: p,
                                completed: completed,
                                money: _money,
                                onEdit: () => _addProduct(p),
                                onPurchasedChanged: (value) async {
                                  await _db.setShoppingProductPurchased(
                                    p['id'] as int,
                                    value,
                                  );
                                  if (mounted) setState(_refresh);
                                },
                                onDelete: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => _MovaDialog(
                                      icon: Icons.delete_outline,
                                      title: 'Eliminar producto',
                                      subtitle:
                                          'Esta acción no se puede deshacer.',
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFB42318,
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Eliminar'),
                                        ),
                                      ],
                                      child: Text(
                                        '¿Quieres quitar "${p['name']}" de esta lista?',
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await _db.deleteShoppingProduct(
                                    p['id'] as int,
                                  );
                                  if (mounted) setState(_refresh);
                                },
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total estimado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _money(list['total'] as num),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                          ],
                        ),
                        if (!completed) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _addProduct(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Producto'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0C2340),
                                    side: const BorderSide(
                                      color: Color(0xFF8BC8BF),
                                    ),
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _finishing
                                      ? null
                                      : () => _finalize(list),
                                  icon: const Icon(Icons.receipt_long),
                                  label: _finishing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Finalizar'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C2340),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductInput {
  final String name, unit;
  final String priceUnit;
  final double quantity;
  final double? price;
  final String note;
  const _ProductInput(
    this.name,
    this.unit,
    this.quantity,
    this.price,
    this.note,
    this.priceUnit,
  );
}

class _RenameDialog extends StatefulWidget {
  final String initial;
  const _RenameDialog({required this.initial});
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => _MovaDialog(
    icon: Icons.edit_note_rounded,
    title: 'Renombrar lista',
    subtitle: 'Usa un nombre fácil de reconocer.',
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded),
        label: const Text('Guardar'),
      ),
    ],
    child: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          'Nombre',
          Icons.list_alt_rounded,
          'Ej. Compras del mes',
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
      ),
    ),
  );
}

class _ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  const _ProductDialog({this.product});
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  static const _units = [
    'pieza',
    'piezas',
    'tapa',
    'tapas',
    'docena',
    'media docena',
    'gramo',
    'gramos',
    'kilogramo',
    'kilogramos',
    'mililitro',
    'mililitros',
    'litro',
    'litros',
    'metro',
    'metros',
    'paquete',
    'paquetes',
    'caja',
    'cajas',
    'cartón',
    'cartones',
    'bolsa',
    'bolsas',
    'botella',
    'botellas',
    'lata',
    'latas',
    'frasco',
    'frascos',
    'rollo',
    'rollos',
    'sobre',
    'sobres',
    'charola',
    'charolas',
    'bandeja',
    'bandejas',
    'racimo',
    'racimos',
    'manojo',
    'manojos',
  ];
  late final TextEditingController _name,
      _unit,
      _quantity,
      _price,
      _priceUnit,
      _note;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] as String? ?? '');
    _unit = TextEditingController(text: p?['unit'] as String? ?? 'pieza');
    _quantity = TextEditingController(text: p?['quantity']?.toString() ?? '1');
    _price = TextEditingController(
      text: p?['unit_price'] == null || p?['unit_price'] == 0
          ? ''
          : p!['unit_price'].toString(),
    );
    _priceUnit = TextEditingController(
      text: p?['price_unit'] as String? ?? _unit.text,
    );
    _note = TextEditingController(text: p?['note'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _quantity.dispose();
    _price.dispose();
    _priceUnit.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final q = double.tryParse(_quantity.text.replaceAll(',', '.'));
    final p = _price.text.trim().isEmpty
        ? null
        : double.tryParse(_price.text.replaceAll(',', '.'));
    if (_name.text.trim().isEmpty ||
        q == null ||
        q <= 0 ||
        (p != null && p < 0)) {
      showMovaError(
        context,
        'Completa el producto con valores válidos.',
        title: 'Revisa el producto',
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      _ProductInput(_name.text, _unit.text, q, p, _note.text, _priceUnit.text),
    );
  }

  @override
  Widget build(BuildContext context) => _MovaDialog(
    icon: widget.product == null
        ? Icons.add_shopping_cart_rounded
        : Icons.edit_rounded,
    title: widget.product == null ? 'Agregar producto' : 'Editar producto',
    subtitle: 'Define qué necesitas y calcula el costo al instante.',
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded),
        label: const Text('Guardar'),
      ),
    ],
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              'Producto',
              Icons.shopping_basket_outlined,
              'Ej. Leche',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _units.contains(_unit.text) ? _unit.text : null,
            decoration: _inputDecoration(
              'Unidad',
              Icons.straighten_rounded,
              'Selecciona una unidad',
            ),
            items: _units
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (value) {
              if (value != null) _unit.text = value;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Cantidad',
                    Icons.numbers_rounded,
                    '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Precio opcional',
                    Icons.attach_money_rounded,
                    '0.00',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'El precio se aplicará por:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _units.contains(_priceUnit.text)
                ? _priceUnit.text
                : _unit.text,
            decoration: _inputDecoration(
              'Unidad del precio',
              Icons.sell_outlined,
              'Ej. kilogramo',
            ),
            items: _units
                .map(
                  (unit) =>
                      DropdownMenuItem(value: unit, child: Text('Por $unit')),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _priceUnit.text = value;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              'Nota (opcional)',
              Icons.notes_rounded,
              'Marca o detalle',
            ),
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}

InputDecoration _inputDecoration(String label, IconData icon, String hint) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF0C2340), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0C2340), width: 1.5),
      ),
    );

class _ListInput {
  final String name, store, notes;
  final double? budget;
  final DateTime? date;
  const _ListInput(this.name, this.store, this.budget, this.date, this.notes);
}

class _ListDialog extends StatefulWidget {
  const _ListDialog();
  @override
  State<_ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<_ListDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _store = TextEditingController();
  final _budget = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _store.dispose();
    _budget.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final budget = _budget.text.trim().isEmpty
        ? null
        : double.parse(_budget.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      _ListInput(_name.text, _store.text, budget, _date, _notes.text),
    );
  }

  @override
  Widget build(BuildContext context) => _MovaDialog(
    icon: Icons.playlist_add_rounded,
    title: 'Nueva lista',
    subtitle: 'Planifica tu próxima compra.',
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded),
        label: const Text('Crear lista'),
      ),
    ],
    child: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Nombre de la lista',
                Icons.list_alt_rounded,
                'Ej. Compras de la semana',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _store,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Tienda (opcional)',
                Icons.storefront_outlined,
                'Ej. Supermercado',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Presupuesto',
                      Icons.account_balance_wallet_outlined,
                      'Opcional',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      return n == null || n < 0 ? 'Monto inválido' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        'Fecha',
                        Icons.event_outlined,
                        'Opcional',
                      ),
                      child: Text(
                        _date == null
                            ? 'Sin fecha'
                            : '${_date!.day}/${_date!.month}/${_date!.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Notas (opcional)',
                Icons.notes_rounded,
                'Agrega un recordatorio',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MovaDialog extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget child;
  final List<Widget> actions;
  const _MovaDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actions,
  });
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0C2340),
        primary: const Color(0xFF0C2340),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0C2340),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0C2340),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        insetAnimationDuration: Duration.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: (MediaQuery.sizeOf(context).height - 48)
                .clamp(240.0, double.infinity)
                .toDouble(),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C2340).withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F4FA), Color(0xFFEAF6FA)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: const Color(0xFF0C2340)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    child,
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
