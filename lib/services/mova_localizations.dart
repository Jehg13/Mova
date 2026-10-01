import 'package:flutter/widgets.dart';
import 'package:mova/services/language_controller.dart';

class MovaLocalizations {
  const MovaLocalizations(this.locale);

  final Locale locale;

  static const delegate = _MovaLocalizationsDelegate();

  static const _values = <String, Map<String, String>>{
    'es': {
      'home': 'Inicio',
      'preparing_finances': 'Preparando tu espacio financiero',
      'my_profile': 'Mi perfil',
      'my_account': 'Mi cuenta',
      'analysis': 'Análisis',
      'goals': 'Metas',
      'more': 'Más',
      'today': 'Hoy',
      'tomorrow': 'Mañana',
      'this_week': 'Esta semana',
      'previous_week': 'Semana anterior',
      'this_month': 'Este mes',
      'previous_month': 'Mes anterior',
      'this_year': 'Este año',
      'previous_year': 'Año anterior',
      'analysis_subtitle': 'Conoce el comportamiento de tus finanzas',
      'home_summary': 'Este es tu resumen financiero',
      'hello': 'Hola',
      'daily_activity': 'Actividad diaria',
      'day_mon': 'Lun',
      'day_tue': 'Mar',
      'day_wed': 'Mié',
      'day_thu': 'Jue',
      'day_fri': 'Vie',
      'day_sat': 'Sáb',
      'day_sun': 'Dom',
      'splash_tagline': 'Tu dinero, en movimiento.',
      'splash_motto': 'CONTROL • CLARIDAD • TRANQUILIDAD',
      'security_intro': 'Elige una sola forma de proteger tu sesión',
      'security_exclusive_note': 'Solo una opción puede estar activa. Al elegir otra, la protección anterior se reemplaza.',
      'expenses_by_category': 'Gastos por categoría',
      'no_period_expenses': 'Aún no hay gastos registrados en este periodo.',
      'record_movements_recommendations':
          'Registra movimientos para obtener recomendaciones.',
      'income': 'Ingresos',
      'expenses': 'Gastos',
      'balance': 'Balance',
      'period_summary': 'Resumen del periodo',
      'no_period_movements': 'No hay movimientos en este periodo.',
      'login_access': 'ACCESO PERSONAL',
      'welcome_back': 'Bienvenido de nuevo',
      'continue_finances': 'Continúa organizando tus finanzas.',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'remember_me': 'Recuérdame',
      'login': 'Iniciar sesión',
      'create_account': 'Crear cuenta',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'no_account': '¿Aún no tienes una cuenta? ',
      'incorrect_data': 'Datos incorrectos',
      'missing_data': 'Faltan datos',
      'complete_fields': 'Completa todos los campos.',
      'personal_budget': 'Presupuesto',
      'notifications': 'Notificaciones',
      'security': 'Seguridad',
      'language': 'Idioma',
      'categories': 'Categorías',
      'shopping_lists': 'Listas de compras',
      'terms': 'Términos y condiciones',
      'privacy': 'Aviso de privacidad',
      'settings': 'Configuración',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'done': 'Listo',
      'select_language': 'Selecciona un idioma',
      'spanish': 'Español',
      'english': 'Inglés',
      'portuguese': 'Portugués',
      'english_native': 'English',
      'portuguese_native': 'Português',
      'spanish_native': 'Español',
      'unlock_mova': 'Desbloquear MOVA',
      'enter_pin': 'Ingresa tu PIN',
      'incorrect_pin': 'PIN incorrecto',
      'incorrect_pin_message': 'El PIN ingresado no es correcto.',
      'loading_section': 'Cargando tu sección',
      'movements': 'Movimientos',
      'financial_activity': 'Tu actividad financiera, en un solo lugar.',
      'all': 'Todos',
      'savings': 'Ahorro',
      'no_movements_filter': 'No hay movimientos en este filtro.',
      'add_income': 'Agregar ingreso',
      'add_expense': 'Agregar gasto',
      'income_help': 'Registra el dinero que recibiste',
      'expense_help': 'Registra en qué utilizaste tu dinero',
      'expense': 'Gasto',
      'income_singular': 'Ingreso',
      'how_much_received': '¿Cuánto recibiste?',
      'how_much': '¿Cuánto?',
      'what_spent': '¿En qué gastaste?',
      'income_source': 'Fuente del ingreso',
      'category': 'Categoría',
      'optional_note': 'Agregar nota (opcional)',
      'save_income': 'Guardar ingreso',
      'save_movement': 'Guardar movimiento',
      'receipt_scan': 'Escanear comprobante',
      'receipt_scanner_title': 'Escanear comprobante',
      'receipt_scanner_help': 'Toma una foto o elige una imagen. Revisa y corrige los datos antes de continuar.',
      'receipt_take_photo': 'Tomar foto',
      'receipt_choose_photo': 'Elegir imagen',
      'receipt_retry_ocr': 'Intentar leer de nuevo',
      'receipt_merchant': 'Comercio o descripción',
      'receipt_amount': 'Importe',
      'receipt_date': 'Fecha del comprobante',
      'receipt_reference': 'Folio o referencia (opcional)',
      'receipt_items': 'Detalle de productos (opcional)',
      'receipt_continue_to_expense': 'Continuar al gasto',
      'receipt_select_image': 'Toma una foto o elige una imagen.',
      'receipt_merchant_required': 'Escribe el comercio o la descripción.',
      'receipt_amount_required': 'Completa un importe válido mayor que cero.',
      'receipt_total_not_found':
          'No se encontró un total claro. Revísalo y escríbelo manualmente.',
      'receipt_ocr_failed': 'No se pudo leer el comprobante. Puedes completar los datos manualmente.',
      'receipt_draft_attached':
          'Comprobante listo; revisa los datos del gasto.',
      'receipt_remove': 'Quitar comprobante',
      'receipt_view': 'Ver comprobante',
      'receipt_duplicate_title': 'Posible gasto duplicado',
      'receipt_duplicate_message': 'Ya existe un gasto del mismo importe y fecha que podría corresponder a este comprobante.',
      'receipt_duplicate_existing': 'Movimiento existente',
      'receipt_save_duplicate': 'Registrar de todos modos',
      'receipt_attach_existing': 'Adjuntar comprobante a este gasto',
      'receipt_has_attachment': 'Ya tiene un comprobante asociado',
      'receipt_attached_existing': 'Comprobante adjuntado al gasto existente.',
      'backups_title': 'Backups',
      'backups_subtitle': 'Crea, comparte y restaura tus copias de seguridad',
      'backup_create_now': 'Crear backup ahora',
      'backup_auto_title': 'Backups automáticos',
      'backup_auto_enabled': 'Backup automático',
      'backup_frequency': 'Frecuencia',
      'backup_daily': 'Diario',
      'backup_weekly': 'Semanal',
      'backup_monthly': 'Mensual',
      'backup_retention': 'Conservar backups automáticos',
      'backup_count': 'backups',
      'backup_last': 'Último backup',
      'backup_next': 'Próximo backup estimado',
      'backup_location': 'Ubicación',
      'backup_location_local': 'Almacenamiento local',
      'backup_too_large': 'El archivo supera el tamaño máximo permitido.',
      'backup_local_note': 'El backup automático se ejecuta cuando abres o vuelves a MOVA; Android e iOS no garantizan una hora exacta en segundo plano.',
      'backup_my_files': 'Mis backups',
      'backup_empty': 'Aún no tienes backups guardados.',
      'backup_manual': 'Manual',
      'backup_automatic': 'Automático',
      'backup_pre_restore': 'Antes de restaurar',
      'backup_save_file': 'Guardar archivo',
      'backup_share': 'Compartir',
      'backup_import': 'Importar backup',
      'backup_restore': 'Restaurar backup',
      'backup_delete': 'Eliminar backup',
      'backup_restore_warning': 'Restaurar reemplazará tus movimientos, cuentas, metas, categorías, suscripciones, pagos, listas y preferencias. Tu sesión y credenciales de acceso se conservarán.',
      'backup_before_restore': 'Primero se guardará un backup de seguridad.',
      'backup_created': 'Backup creado correctamente.',
      'backup_restored': 'Backup restaurado correctamente.',
      'backup_invalid': 'Archivo inválido o dañado.',
      'backup_failed': 'No se pudo completar el backup.',
      'backup_incompatible': 'El backup usa una versión incompatible.',
      'backup_restore_confirm': 'Restaurar y reemplazar',
      'backup_version': 'Versión del formato',
      'backup_transactions': 'Movimientos',
      'backup_goals': 'Metas',
      'backup_accounts': 'Cuentas',
      'backup_subscriptions': 'Suscripciones',
      'backup_file_saved': 'Archivo guardado correctamente.',
      'backup_delete_confirm':
          '¿Eliminar este backup? Esta acción no se puede deshacer.',
      'backup_cancelled': 'Restauración cancelada.',
      'create_your_account': 'Crea tu cuenta',
      'take_control': 'Empieza a tomar el control de tus finanzas.',
      'name': 'Nombre',
      'enter_name': 'Ingresa tu nombre',
      'enter_email': 'Ingresa tu correo',
      'create_password': 'Crea una contraseña',
      'repeat_password': 'Repite tu contraseña',
      'my_goals': 'Mis metas',
      'goals_subtitle': 'Convierte tus planes en objetivos',
      'goal_almost_complete': '¡Ya casi alcanzas tu meta!',
      'new_goal': 'Nueva meta',
      'free_savings': 'Ahorro libre',
      'free_savings_help': 'Ahorra sin tener una meta específica',
      'no_goals_yet': 'Aún no tienes metas',
      'create_goal_savings':
          'Crea una meta para darle un objetivo a tus ahorros.',
      'no_goals_home': 'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.',
      'add': 'Agregar',
      'withdraw': 'Retirar',
      'amount': 'Cantidad',
      'close': 'Cerrar',
      'my_shopping': 'Mis compras',
      'current': 'Actuales',
      'history': 'Historial',
      'new_list': 'Nueva lista',
      'no_completed_shopping': 'Aún no hay compras finalizadas',
      'plan_first_shopping': 'Planea tu primera compra',
      'create_list': 'Crear lista',
      'understood': 'Entendido',
      'something_wrong': 'Algo salió mal',
      'ready': 'Listo',
      'finance': 'FINANZAS',
      'your_money': 'Tu dinero.\nTus metas.\nTu control.',
      'welcome_subtitle': 'Organiza, ahorra y avanza con claridad.',
      'already_account': 'Ya tengo una cuenta',
      'protected_data': 'Tus datos están protegidos',
      'logout': 'Cerrar sesión',
      'close_session': '¿Quieres cerrar tu sesión?',
      'notifications_active': 'Notificaciones activas',
      'savings_goals': 'Metas de ahorro',
      'shopping': 'Compras',
      'view_all': 'Ver todos',
      'no_summary': 'No se pudo cargar el resumen',
      'recover_access': 'Recupera tu acceso',
      'new_password': 'Nueva contraseña',
      'confirm_password': 'Confirmar contraseña',
      'update': 'Actualizar',
      'saving': 'Guardando...',
      'verify': 'Verificar',
      'cancelled': 'Cancelado',
      'account_options': 'Opciones de cuenta',
      'preferences': 'Preferencias y opciones de MOVA',
      'exit_device': 'Salir de tu cuenta en este dispositivo',
      'choose_notifications': 'Elige qué avisos quieres recibir en MOVA.',
      'allow_notifications': 'Permitir notificaciones',
      'notifications_help': 'Activa o pausa todos los avisos de MOVA',
      'notification_types': 'TIPOS DE AVISO',
      'budget_help': 'Avisos relacionados con tu presupuesto',
      'goals_help': 'Recordatorios para avanzar en tus objetivos',
      'shopping_help': 'Recordatorios de listas pendientes',
      'my_subscriptions': 'Mis suscripciones',
      'my_accounts': 'Mis cuentas',
      'manage_accounts': 'Administra dónde está tu dinero',
      'money_by_account': 'Dinero por cuenta',
      'money_by_account_hint':
          'Consulta tus saldos y mueve dinero entre cuentas.',
      'credit_card_transfer_note': 'El saldo de tarjetas de crédito es deuda. Puedes pagarla desde otra cuenta, pero no retirarla como efectivo.',
      'new_account': 'Nueva cuenta',
      'edit_account': 'Editar cuenta',
      'accounts_load_error': 'No se pudieron cargar las cuentas.',
      'account_not_found': 'No se encontró esta cuenta.',
      'accounts_empty': 'Aún no tienes cuentas. Agrega una para empezar.',
      'account_name': 'Nombre de la cuenta',
      'account_name_hint': 'Ej. BBVA o Visa',
      'account_type': 'Tipo de cuenta',
      'account_type_cash': 'Efectivo',
      'account_type_bank': 'Cuenta bancaria',
      'account_type_debitCard': 'Tarjeta de débito',
      'account_type_creditCard': 'Tarjeta de crédito',
      'account_type_savings': 'Cuenta de ahorro',
      'initial_balance': 'Saldo inicial disponible',
      'initial_card_debt': 'Deuda actual de la tarjeta',
      'credit_limit': 'Límite de crédito',
      'invalid_initial_balance': 'Ingresa un saldo inicial válido.',
      'invalid_credit_limit': 'El límite debe ser mayor que la deuda actual.',
      'institution_optional': 'Institución (opcional)',
      'institution_hint': 'Ej. BBVA',
      'institution': 'Institución',
      'last_four_optional': 'Últimos 4 dígitos (opcional)',
      'last_four': 'Últimos 4 dígitos',
      'save_account': 'Guardar cuenta',
      'account_activity': 'Movimientos y transferencias',
      'activity_load_error': 'No se pudo cargar la actividad.',
      'no_account_activity': 'Aún no hay actividad en esta cuenta.',
      'account_optional': 'Cuenta (opcional)',
      'no_account_selected': 'Sin cuenta asignada',
      'available_to_spend': 'Disponible para gastar',
      'money_in_accounts': 'Dinero en cuentas',
      'credit_debt': 'Deuda en tarjetas',
      'credit_available': 'Crédito disponible',
      'allocated_savings_and_goals': 'Apartado en ahorro y metas',
      'general_savings': 'Ahorro general',
      'cash_accounts': 'Efectivo',
      'bank_accounts': 'Bancos y tarjetas',
      'inactive': 'Inactiva',
      'deactivate_account': 'Desactivar cuenta',
      'transfer': 'Transferencia',
      'transfer_money': 'Transferir dinero',
      'source_account': 'Cuenta de origen',
      'destination_account': 'Cuenta de destino',
      'saving_source_label': 'Cuenta de origen',
      'saving_destination_label': 'Cuenta de destino',
      'account_real_balance_label': 'Saldo real',
      'account_available_label': 'Disponible',
      'account_allocated_label': 'Apartado',
      'unassigned_savings_account_label': 'Ahorro libre sin cuenta asignada',
      'date': 'Fecha',
      'payments_summary': 'Resumen de pagos',
      'payments_next_7_days': 'Próximos 7 días',
      'payments_next_30_days': 'Próximos 30 días',
      'payments_pending_total': 'Total pendiente',
      'money_committed': 'Dinero comprometido',
      'add_payment': 'Nuevo pago',
      'edit_payment': 'Editar pago',
      'payment_name': 'Nombre del pago',
      'payment_name_hint': 'Ej. Renta, Internet o tarjeta Visa',
      'payment_type': 'Tipo de pago',
      'payment_type_recurring': 'Pago recurrente',
      'payment_type_one_time': 'Pago único',
      'payment_type_card': 'Pago de tarjeta',
      'payment_frequency_optional': 'Frecuencia',
      'payment_due_date': 'Fecha de pago',
      'payment_category': 'Categoría del gasto',
      'payment_account': 'Cuenta de pago (opcional)',
      'payment_card': 'Tarjeta que se pagará',
      'payment_method': 'Método de pago',
      'payment_method_unspecified': 'No especificado',
      'payment_account_used': 'Cuenta utilizada',
      'mark_payment_paid': 'Marcar como pagado',
      'confirm_payment_title': 'Confirmar pago',
      'confirm_payment_message': '¿Confirmar el pago de {amount}?',
      'find_duplicate_payment':
          'Ya existe un gasto que coincide con este pago.',
      'create_payment_movement': 'Registrar un nuevo gasto',
      'payment_saved': 'Pago registrado correctamente.',
      'payment_cancelled': 'Pago cancelado.',
      'payment_load_error': 'No se pudieron cargar los pagos.',
      'payment_save_error': 'No se pudo guardar el pago.',
      'no_scheduled_payments': 'No tienes pagos pendientes programados.',
      'no_payment_history': 'Todavía no hay pagos en el historial.',
      'payment_filters': 'Filtros',
      'payment_filter_type': 'Tipo',
      'payment_filter_status': 'Estado',
      'payment_filter_category': 'Categoría',
      'payment_filter_account': 'Cuenta',
      'payment_filter_all': 'Todos los pagos',
      'payment_status_pending': 'Pendiente',
      'payment_status_overdue': 'Vencido',
      'payment_status_paid': 'Pagado',
      'payment_status_cancelled': 'Cancelado',
      'payment_type_subscription': 'Suscripción',
      'payment_type_filter_recurring': 'Recurrentes',
      'payment_type_filter_card': 'Tarjetas',
      'payment_type_filter_one_time': 'Pagos únicos',
      'payment_type_filter_subscription': 'Suscripciones',
      'payment_time_all': 'Todo',
      'payment_time_7_days': '7 días',
      'payment_time_30_days': '30 días',
      'payment_time_this_month': 'Este mes',
      'payment_time_next_month': 'Próximo mes',
      'payment_overdue_since': 'Venció el {date}',
      'payment_days_overdue': 'Vencido · {count} días',
      'payment_not_expense_yet':
          'Los pagos futuros no se registran como gastos.',
      'payment_cancel_confirm': '¿Cancelar este pago programado?',
      'subscriptions': 'Suscripciones',
      'manage_recurring_payments': 'Administra tus pagos recurrentes',
      'upcoming_payments': 'Próximos pagos',
      'upcoming_payments_total': 'Total próximos pagos',
      'no_active_subscriptions': 'No tienes suscripciones activas.',
      'subscription_reminders_help': 'Avisos antes de tus próximos cobros',
      'payment_reminders_help': 'Avisos antes de pagos próximos',
      'new_subscription': 'Nueva suscripción',
      'subscriptions_load_error': 'No se pudieron cargar las suscripciones.',
      'active_subscriptions': 'Suscripciones activas',
      'estimated_monthly_spend': 'Gasto mensual estimado',
      'estimated_annual_spend': 'Gasto anual estimado',
      'upcoming_charges': 'Próximos cobros',
      'no_upcoming_charges': 'No hay cobros en los próximos 30 días.',
      'all_subscriptions': 'Todas las suscripciones',
      'subscriptions_empty': 'Aún no tienes suscripciones. Agrega la primera.',
      'days_count': 'En {count} días',
      'active': 'Activa',
      'paused': 'Pausada',
      'next_charge': 'Próximo cobro',
      'frequency_weekly': 'semana',
      'frequency_biweekly': 'quincena',
      'frequency_monthly': 'mes',
      'frequency_bimonthly': 'bimestre',
      'frequency_quarterly': 'trimestre',
      'frequency_semiannual': 'semestre',
      'frequency_annual': 'año',
      'edit_subscription': 'Editar suscripción',
      'subscription_name': 'Nombre',
      'subscription_name_hint': 'Ej. Netflix',
      'description_optional': 'Descripción (opcional)',
      'amount_and_currency': 'Importe y moneda',
      'currency': 'Moneda',
      'frequency': 'Frecuencia',
      'account_or_card': 'Cuenta o tarjeta (opcional)',
      'account_hint': 'Ej. Visa •••• 4582',
      'payment_reminder': 'Aviso de cobro',
      'same_day': 'El mismo día',
      'days_before': '{count} días antes',
      'notes_optional': 'Notas (opcional)',
      'required_field': 'Este campo es obligatorio.',
      'amount_must_be_positive': 'Ingresa un importe mayor que cero.',
      'save_error': 'No se pudo guardar',
      'reminder_schedule_error':
          'Se guardó el cambio, pero no se pudo programar el aviso',
      'save_subscription': 'Guardar suscripción',
      'possible_duplicate': '¿Ya registraste este gasto?',
      'possible_duplicate_body': 'Hay un gasto con el mismo importe y categoría en la fecha del cobro. Puedes asociarlo para evitar duplicarlo.',
      'link_existing_movement': 'Asociar gasto existente',
      'create_expense_anyway': 'Registrar otro gasto',
      'subscription_payment_saved': 'Pago de suscripción registrado.',
      'delete_subscription': 'Eliminar suscripción',
      'delete_subscription_confirmation': 'Se eliminará la suscripción y su historial. Los movimientos ya registrados se conservarán.',
      'delete': 'Eliminar',
      'pause': 'Pausar',
      'reactivate': 'Reactivar',
      'cancel_subscription': 'Cancelar suscripción',
      'every': 'Cada',
      'description': 'Descripción',
      'notes': 'Notas',
      'mark_as_paid': 'Marcar como pagado',
      'payment_history': 'Historial de pagos',
      'history_load_error': 'No se pudo cargar el historial.',
      'no_subscription_payments': 'Aún no hay pagos registrados.',
      'paid': 'Pagado',
      'month_jan': 'ene',
      'month_feb': 'feb',
      'month_mar': 'mar',
      'month_apr': 'abr',
      'month_may': 'may',
      'month_jun': 'jun',
      'month_jul': 'jul',
      'month_aug': 'ago',
      'month_sep': 'sep',
      'month_oct': 'oct',
      'month_nov': 'nov',
      'month_dec': 'dic',
      'Sal de tu cuenta en este dispositivo':
          'Sal de tu cuenta en este dispositivo',
      'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.': 'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.',
      'Crea una meta para darle un objetivo a tus ahorros.':
          'Crea una meta para darle un objetivo a tus ahorros.',
      'Gastos por categoría': 'Gastos por categoría',
      'Aún no hay gastos registrados en este periodo.':
          'Aún no hay gastos registrados en este periodo.',
      'Registra movimientos para obtener recomendaciones.':
          'Registra movimientos para obtener recomendaciones.',
    },
    'en': {
      'home': 'Home',
      'preparing_finances': 'Preparing your financial space',
      'showing_current_period': 'showing the current period',
      'my_profile': 'My profile',
      'my_account': 'My account',
      'analysis': 'Analytics',
      'goals': 'Goals',
      'more': 'More',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'this_week': 'This week',
      'previous_week': 'Previous week',
      'this_month': 'This month',
      'previous_month': 'Previous month',
      'this_year': 'This year',
      'previous_year': 'Previous year',
      'analysis_subtitle': 'Understand your financial behavior',
      'home_summary': 'Here is your financial summary',
      'hello': 'Hello',
      'daily_activity': 'Daily activity',
      'day_mon': 'Mon',
      'day_tue': 'Tue',
      'day_wed': 'Wed',
      'day_thu': 'Thu',
      'day_fri': 'Fri',
      'day_sat': 'Sat',
      'day_sun': 'Sun',
      'splash_tagline': 'Your money, in motion.',
      'splash_motto': 'CONTROL • CLARITY • PEACE OF MIND',
      'security_intro': 'Choose one way to protect your session',
      'security_exclusive_note': 'Only one option can be active. Choosing another replaces the previous protection.',
      'expenses_by_category': 'Expenses by category',
      'no_period_expenses': 'There are no expenses recorded in this period.',
      'record_movements_recommendations':
          'Record movements to get recommendations.',
      'income': 'Income',
      'expenses': 'Expenses',
      'balance': 'Balance',
      'period_summary': 'Period summary',
      'no_period_movements': 'There are no movements in this period.',
      'login_access': 'PERSONAL ACCESS',
      'welcome_back': 'Welcome back',
      'continue_finances': 'Keep organizing your finances.',
      'email': 'Email',
      'password': 'Password',
      'remember_me': 'Remember me',
      'login': 'Log in',
      'create_account': 'Create account',
      'forgot_password': 'Forgot your password?',
      'no_account': "Don't have an account? ",
      'incorrect_data': 'Incorrect data',
      'missing_data': 'Missing data',
      'complete_fields': 'Complete all fields.',
      'personal_budget': 'Budget',
      'notifications': 'Notifications',
      'security': 'Security',
      'language': 'Language',
      'categories': 'Categories',
      'shopping_lists': 'Shopping lists',
      'terms': 'Terms and conditions',
      'privacy': 'Privacy notice',
      'settings': 'Settings',
      'save': 'Save',
      'cancel': 'Cancel',
      'done': 'Done',
      'select_language': 'Select a language',
      'spanish': 'Spanish',
      'english': 'English',
      'portuguese': 'Portuguese',
      'english_native': 'English',
      'portuguese_native': 'Português',
      'spanish_native': 'Español',
      'unlock_mova': 'Unlock MOVA',
      'enter_pin': 'Enter your PIN',
      'incorrect_pin': 'Incorrect PIN',
      'incorrect_pin_message': 'The PIN entered is incorrect.',
      'loading_section': 'Loading your section',
      'movements': 'Movements',
      'financial_activity': 'Your financial activity, all in one place.',
      'all': 'All',
      'savings': 'Savings',
      'no_movements_filter': 'There are no movements for this filter.',
      'add_income': 'Add income',
      'add_expense': 'Add expense',
      'income_help': 'Record money you received',
      'expense_help': 'Record how you used your money',
      'expense': 'Expense',
      'income_singular': 'Income',
      'how_much_received': 'How much did you receive?',
      'how_much': 'How much?',
      'what_spent': 'What did you spend it on?',
      'income_source': 'Income source',
      'category': 'Category',
      'optional_note': 'Add note (optional)',
      'save_income': 'Save income',
      'save_movement': 'Save movement',
      'receipt_scan': 'Scan receipt',
      'receipt_scanner_title': 'Scan receipt',
      'receipt_scanner_help': 'Take a photo or choose an image. Review and correct the details before continuing.',
      'receipt_take_photo': 'Take photo',
      'receipt_choose_photo': 'Choose image',
      'receipt_retry_ocr': 'Try reading again',
      'receipt_merchant': 'Merchant or description',
      'receipt_amount': 'Amount',
      'receipt_date': 'Receipt date',
      'receipt_reference': 'Reference (optional)',
      'receipt_items': 'Item details (optional)',
      'receipt_continue_to_expense': 'Continue to expense',
      'receipt_select_image': 'Take a photo or choose an image.',
      'receipt_merchant_required': 'Enter the merchant or description.',
      'receipt_amount_required': 'Enter a valid amount greater than zero.',
      'receipt_total_not_found':
          'No clear total was found. Review it and enter it manually.',
      'receipt_ocr_failed':
          'The receipt could not be read. You can enter the details manually.',
      'receipt_draft_attached': 'Receipt ready; review the expense details.',
      'receipt_remove': 'Remove receipt',
      'receipt_view': 'View receipt',
      'receipt_duplicate_title': 'Possible duplicate expense',
      'receipt_duplicate_message': 'An expense with the same amount and date may already match this receipt.',
      'receipt_duplicate_existing': 'Existing transaction',
      'receipt_save_duplicate': 'Save anyway',
      'receipt_attach_existing': 'Attach receipt to this expense',
      'receipt_has_attachment': 'A receipt is already attached',
      'receipt_attached_existing': 'Receipt attached to the existing expense.',
      'backups_title': 'Backups',
      'backups_subtitle': 'Create, share, and restore your backups',
      'backup_create_now': 'Create backup now',
      'backup_auto_title': 'Automatic backups',
      'backup_auto_enabled': 'Automatic backup',
      'backup_frequency': 'Frequency',
      'backup_daily': 'Daily',
      'backup_weekly': 'Weekly',
      'backup_monthly': 'Monthly',
      'backup_retention': 'Keep automatic backups',
      'backup_count': 'backups',
      'backup_last': 'Last backup',
      'backup_next': 'Next estimated backup',
      'backup_location': 'Location',
      'backup_location_local': 'Local storage',
      'backup_too_large': 'The file exceeds the maximum allowed size.',
      'backup_local_note': 'Automatic backups run when you open or return to MOVA; Android and iOS do not guarantee an exact background schedule.',
      'backup_my_files': 'My backups',
      'backup_empty': 'You do not have any saved backups yet.',
      'backup_manual': 'Manual',
      'backup_automatic': 'Automatic',
      'backup_pre_restore': 'Before restore',
      'backup_save_file': 'Save file',
      'backup_share': 'Share',
      'backup_import': 'Import backup',
      'backup_restore': 'Restore backup',
      'backup_delete': 'Delete backup',
      'backup_restore_warning': 'Restoring replaces your transactions, accounts, goals, categories, subscriptions, payments, lists, and preferences. Your session and login credentials are kept.',
      'backup_before_restore': 'A safety backup will be created first.',
      'backup_created': 'Backup created successfully.',
      'backup_restored': 'Backup restored successfully.',
      'backup_invalid': 'The file is invalid or damaged.',
      'backup_failed': 'The backup could not be completed.',
      'backup_incompatible': 'The backup uses an incompatible version.',
      'backup_restore_confirm': 'Restore and replace',
      'backup_version': 'Format version',
      'backup_transactions': 'Transactions',
      'backup_goals': 'Goals',
      'backup_accounts': 'Accounts',
      'backup_subscriptions': 'Subscriptions',
      'backup_file_saved': 'File saved successfully.',
      'backup_delete_confirm':
          'Delete this backup? This action cannot be undone.',
      'backup_cancelled': 'Restore cancelled.',
      'create_your_account': 'Create your account',
      'take_control': 'Start taking control of your finances.',
      'name': 'Name',
      'enter_name': 'Enter your name',
      'enter_email': 'Enter your email',
      'create_password': 'Create a password',
      'repeat_password': 'Repeat your password',
      'my_goals': 'My goals',
      'goals_subtitle': 'Turn your plans into goals',
      'goal_almost_complete': 'You are close to reaching your goal!',
      'new_goal': 'New goal',
      'free_savings': 'Free savings',
      'free_savings_help': 'Save without a specific goal',
      'no_goals_yet': 'You have no goals yet',
      'create_goal_savings': 'Create a goal to give your savings a purpose.',
      'no_goals_home':
          'You have no goals yet. Create one to start saving toward a goal.',
      'add': 'Add',
      'withdraw': 'Withdraw',
      'amount': 'Amount',
      'close': 'Close',
      'my_shopping': 'My shopping',
      'current': 'Current',
      'history': 'History',
      'new_list': 'New list',
      'no_completed_shopping': 'No completed purchases yet',
      'plan_first_shopping': 'Plan your first purchase',
      'create_list': 'Create list',
      'understood': 'Got it',
      'something_wrong': 'Something went wrong',
      'ready': 'Done',
      'finance': 'FINANCE',
      'your_money': 'Your money.\nYour goals.\nYour control.',
      'welcome_subtitle': 'Organize, save, and move forward with clarity.',
      'already_account': 'I already have an account',
      'protected_data': 'Your data is protected',
      'logout': 'Log out',
      'close_session': 'Do you want to log out?',
      'notifications_active': 'Notifications enabled',
      'savings_goals': 'Savings goals',
      'shopping': 'Shopping',
      'view_all': 'View all',
      'no_summary': 'Could not load the summary',
      'recover_access': 'Recover your access',
      'new_password': 'New password',
      'confirm_password': 'Confirm password',
      'update': 'Update',
      'saving': 'Saving...',
      'verify': 'Verify',
      'cancelled': 'Cancelled',
      'account_options': 'Account options',
      'preferences': 'MOVA preferences and options',
      'exit_device': 'Sign out of this device',
      'choose_notifications':
          'Choose which notifications you want to receive in MOVA.',
      'allow_notifications': 'Allow notifications',
      'notifications_help': 'Turn all MOVA alerts on or off',
      'notification_types': 'NOTIFICATION TYPES',
      'budget_help': 'Alerts related to your budget',
      'goals_help': 'Reminders to advance your goals',
      'shopping_help': 'Reminders for pending lists',
      'my_subscriptions': 'My subscriptions',
      'my_accounts': 'My accounts',
      'manage_accounts': 'Manage where your money is kept',
      'money_by_account': 'Money by account',
      'money_by_account_hint':
          'Review balances and move money between accounts.',
      'credit_card_transfer_note': 'Credit card balances are debt. You can pay them from another account, but cannot withdraw them as cash.',
      'new_account': 'New account',
      'edit_account': 'Edit account',
      'accounts_load_error': 'Could not load accounts.',
      'account_not_found': 'Account not found.',
      'accounts_empty': 'You have no accounts yet. Add one to get started.',
      'account_name': 'Account name',
      'account_name_hint': 'e.g. BBVA or Visa',
      'account_type': 'Account type',
      'account_type_cash': 'Cash',
      'account_type_bank': 'Bank account',
      'account_type_debitCard': 'Debit card',
      'account_type_creditCard': 'Credit card',
      'account_type_savings': 'Savings account',
      'initial_balance': 'Initial available balance',
      'initial_card_debt': 'Current card debt',
      'credit_limit': 'Credit limit',
      'invalid_initial_balance': 'Enter a valid initial balance.',
      'invalid_credit_limit': 'The limit must cover the current debt.',
      'institution_optional': 'Institution (optional)',
      'institution_hint': 'e.g. BBVA',
      'institution': 'Institution',
      'last_four_optional': 'Last 4 digits (optional)',
      'last_four': 'Last 4 digits',
      'save_account': 'Save account',
      'account_activity': 'Transactions and transfers',
      'activity_load_error': 'Could not load account activity.',
      'no_account_activity': 'No activity on this account yet.',
      'account_optional': 'Account (optional)',
      'no_account_selected': 'No account assigned',
      'available_to_spend': 'Available to spend',
      'money_in_accounts': 'Money in accounts',
      'credit_debt': 'Credit card debt',
      'credit_available': 'Available credit',
      'allocated_savings_and_goals': 'Allocated to savings and goals',
      'general_savings': 'General savings',
      'cash_accounts': 'Cash',
      'bank_accounts': 'Banks and cards',
      'inactive': 'Inactive',
      'deactivate_account': 'Deactivate account',
      'transfer': 'Transfer',
      'transfer_money': 'Transfer money',
      'source_account': 'From account',
      'destination_account': 'To account',
      'saving_source_label': 'From account',
      'saving_destination_label': 'To account',
      'account_real_balance_label': 'Actual balance',
      'account_available_label': 'Available',
      'account_allocated_label': 'Set aside',
      'unassigned_savings_account_label':
          'Free savings not assigned to an account',
      'date': 'Date',
      'payments_summary': 'Payment summary',
      'payments_next_7_days': 'Next 7 days',
      'payments_next_30_days': 'Next 30 days',
      'payments_pending_total': 'Total pending',
      'money_committed': 'Committed money',
      'add_payment': 'New payment',
      'edit_payment': 'Edit payment',
      'payment_name': 'Payment name',
      'payment_name_hint': 'e.g. Rent, Internet, or Visa card',
      'payment_type': 'Payment type',
      'payment_type_recurring': 'Recurring payment',
      'payment_type_one_time': 'One-time payment',
      'payment_type_card': 'Credit card payment',
      'payment_frequency_optional': 'Frequency',
      'payment_due_date': 'Due date',
      'payment_category': 'Expense category',
      'payment_account': 'Payment account (optional)',
      'payment_card': 'Card to pay',
      'payment_method': 'Payment method',
      'payment_method_unspecified': 'Not specified',
      'payment_account_used': 'Account used',
      'mark_payment_paid': 'Mark as paid',
      'confirm_payment_title': 'Confirm payment',
      'confirm_payment_message': 'Confirm payment of {amount}?',
      'find_duplicate_payment':
          'A matching expense already exists for this payment.',
      'create_payment_movement': 'Record a new expense',
      'payment_saved': 'Payment recorded successfully.',
      'payment_cancelled': 'Payment cancelled.',
      'payment_load_error': 'Could not load payments.',
      'payment_save_error': 'Could not save the payment.',
      'no_scheduled_payments': 'You have no scheduled payments due.',
      'no_payment_history': 'There are no payments in the history yet.',
      'payment_filters': 'Filters',
      'payment_filter_type': 'Type',
      'payment_filter_status': 'Status',
      'payment_filter_category': 'Category',
      'payment_filter_account': 'Account',
      'payment_filter_all': 'All payments',
      'payment_status_pending': 'Pending',
      'payment_status_overdue': 'Overdue',
      'payment_status_paid': 'Paid',
      'payment_status_cancelled': 'Cancelled',
      'payment_type_subscription': 'Subscription',
      'payment_type_filter_recurring': 'Recurring',
      'payment_type_filter_card': 'Cards',
      'payment_type_filter_one_time': 'One-time',
      'payment_type_filter_subscription': 'Subscriptions',
      'payment_time_all': 'All',
      'payment_time_7_days': '7 days',
      'payment_time_30_days': '30 days',
      'payment_time_this_month': 'This month',
      'payment_time_next_month': 'Next month',
      'payment_overdue_since': 'Due on {date}',
      'payment_days_overdue': 'Overdue · {count} days',
      'payment_not_expense_yet':
          'Future payments are not recorded as expenses.',
      'payment_cancel_confirm': 'Cancel this scheduled payment?',
      'subscriptions': 'Subscriptions',
      'manage_recurring_payments': 'Manage recurring payments',
      'upcoming_payments': 'Upcoming payments',
      'upcoming_payments_total': 'Upcoming payments total',
      'no_active_subscriptions': 'You have no active subscriptions.',
      'subscription_reminders_help': 'Alerts before upcoming charges',
      'payment_reminders_help': 'Alerts before upcoming scheduled payments',
      'new_subscription': 'New subscription',
      'subscriptions_load_error': 'Could not load subscriptions.',
      'active_subscriptions': 'Active subscriptions',
      'estimated_monthly_spend': 'Estimated monthly spend',
      'estimated_annual_spend': 'Estimated annual spend',
      'upcoming_charges': 'Upcoming charges',
      'no_upcoming_charges': 'No charges in the next 30 days.',
      'all_subscriptions': 'All subscriptions',
      'subscriptions_empty':
          'You have no subscriptions yet. Add your first one.',
      'days_count': 'In {count} days',
      'active': 'Active',
      'paused': 'Paused',
      'next_charge': 'Next charge',
      'frequency_weekly': 'week',
      'frequency_biweekly': 'two weeks',
      'frequency_monthly': 'month',
      'frequency_bimonthly': 'two months',
      'frequency_quarterly': 'quarter',
      'frequency_semiannual': 'six months',
      'frequency_annual': 'year',
      'edit_subscription': 'Edit subscription',
      'subscription_name': 'Name',
      'subscription_name_hint': 'e.g. Netflix',
      'description_optional': 'Description (optional)',
      'amount_and_currency': 'Amount and currency',
      'currency': 'Currency',
      'frequency': 'Frequency',
      'account_or_card': 'Account or card (optional)',
      'account_hint': 'e.g. Visa •••• 4582',
      'payment_reminder': 'Payment reminder',
      'same_day': 'Same day',
      'days_before': '{count} days before',
      'notes_optional': 'Notes (optional)',
      'required_field': 'This field is required.',
      'amount_must_be_positive': 'Enter an amount greater than zero.',
      'save_error': 'Could not save',
      'reminder_schedule_error':
          'The change was saved, but the reminder could not be scheduled',
      'save_subscription': 'Save subscription',
      'possible_duplicate': 'Did you already record this expense?',
      'possible_duplicate_body': 'An expense with the same amount and category exists on the charge date. Link it to avoid duplicating it.',
      'link_existing_movement': 'Link existing expense',
      'create_expense_anyway': 'Record another expense',
      'subscription_payment_saved': 'Subscription payment recorded.',
      'delete_subscription': 'Delete subscription',
      'delete_subscription_confirmation': 'The subscription and its payment history will be deleted. Existing transactions will be kept.',
      'delete': 'Delete',
      'pause': 'Pause',
      'reactivate': 'Reactivate',
      'cancel_subscription': 'Cancel subscription',
      'every': 'Every',
      'description': 'Description',
      'notes': 'Notes',
      'mark_as_paid': 'Mark as paid',
      'payment_history': 'Payment history',
      'history_load_error': 'Could not load payment history.',
      'no_subscription_payments': 'No payments recorded yet.',
      'paid': 'Paid',
      'month_jan': 'Jan',
      'month_feb': 'Feb',
      'month_mar': 'Mar',
      'month_apr': 'Apr',
      'month_may': 'May',
      'month_jun': 'Jun',
      'month_jul': 'Jul',
      'month_aug': 'Aug',
      'month_sep': 'Sep',
      'month_oct': 'Oct',
      'month_nov': 'Nov',
      'month_dec': 'Dec',
      'Sal de tu cuenta en este dispositivo':
          'Sign out of your account on this device',
      'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.':
          'You have no goals yet. Create one to start saving toward a goal.',
      'Crea una meta para darle un objetivo a tus ahorros.':
          'Create a goal to give your savings a purpose.',
      'Gastos por categoría': 'Expenses by category',
      'Aún no hay gastos registrados en este periodo.':
          'There are no expenses recorded in this period.',
      'Registra movimientos para obtener recomendaciones.':
          'Record movements to get recommendations.',
    },
    'pt': {
      'home': 'Início',
      'preparing_finances': 'Preparando seu espaço financeiro',
      'showing_current_period': 'mostrando o período atual',
      'my_profile': 'Meu perfil',
      'my_account': 'Minha conta',
      'analysis': 'Análise',
      'goals': 'Metas',
      'more': 'Mais',
      'today': 'Hoje',
      'tomorrow': 'Amanhã',
      'this_week': 'Esta semana',
      'previous_week': 'Semana anterior',
      'this_month': 'Este mês',
      'previous_month': 'Mês anterior',
      'this_year': 'Este ano',
      'previous_year': 'Ano anterior',
      'analysis_subtitle': 'Conheça o comportamento das suas finanças',
      'home_summary': 'Este é o seu resumo financeiro',
      'hello': 'Olá',
      'daily_activity': 'Atividade diária',
      'day_mon': 'Seg',
      'day_tue': 'Ter',
      'day_wed': 'Qua',
      'day_thu': 'Qui',
      'day_fri': 'Sex',
      'day_sat': 'Sáb',
      'day_sun': 'Dom',
      'splash_tagline': 'Seu dinheiro em movimento.',
      'splash_motto': 'CONTROLE • CLAREZA • TRANQUILIDADE',
      'security_intro': 'Escolha uma forma de proteger sua sessão',
      'security_exclusive_note': 'Somente uma opção pode estar ativa. Escolher outra substitui a proteção anterior.',
      'expenses_by_category': 'Despesas por categoria',
      'no_period_expenses': 'Ainda não há despesas registradas neste período.',
      'record_movements_recommendations':
          'Registre movimentações para obter recomendações.',
      'income': 'Receitas',
      'expenses': 'Despesas',
      'balance': 'Saldo',
      'period_summary': 'Resumo do período',
      'no_period_movements': 'Não há movimentações neste período.',
      'login_access': 'ACESSO PESSOAL',
      'welcome_back': 'Bem-vindo novamente',
      'continue_finances': 'Continue organizando suas finanças.',
      'email': 'E-mail',
      'password': 'Senha',
      'remember_me': 'Lembrar de mim',
      'login': 'Entrar',
      'create_account': 'Criar conta',
      'forgot_password': 'Esqueceu sua senha?',
      'no_account': 'Ainda não tem uma conta? ',
      'incorrect_data': 'Dados incorretos',
      'missing_data': 'Dados faltando',
      'complete_fields': 'Preencha todos os campos.',
      'personal_budget': 'Orçamento',
      'notifications': 'Notificações',
      'security': 'Segurança',
      'language': 'Idioma',
      'categories': 'Categorias',
      'shopping_lists': 'Listas de compras',
      'terms': 'Termos e condições',
      'privacy': 'Aviso de privacidade',
      'settings': 'Configurações',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'done': 'Concluído',
      'select_language': 'Selecione um idioma',
      'spanish': 'Espanhol',
      'english': 'Inglês',
      'portuguese': 'Português',
      'english_native': 'English',
      'portuguese_native': 'Português',
      'spanish_native': 'Español',
      'unlock_mova': 'Desbloquear MOVA',
      'enter_pin': 'Digite seu PIN',
      'incorrect_pin': 'PIN incorreto',
      'incorrect_pin_message': 'O PIN informado está incorreto.',
      'loading_section': 'Carregando sua seção',
      'movements': 'Movimentações',
      'financial_activity': 'Sua atividade financeira em um só lugar.',
      'all': 'Todas',
      'savings': 'Poupança',
      'no_movements_filter': 'Não há movimentações neste filtro.',
      'add_income': 'Adicionar receita',
      'add_expense': 'Adicionar despesa',
      'income_help': 'Registre o dinheiro que recebeu',
      'expense_help': 'Registre como usou seu dinheiro',
      'expense': 'Despesa',
      'income_singular': 'Receita',
      'how_much_received': 'Quanto você recebeu?',
      'how_much': 'Quanto?',
      'what_spent': 'Com o que você gastou?',
      'income_source': 'Fonte da receita',
      'category': 'Categoria',
      'optional_note': 'Adicionar nota (opcional)',
      'save_income': 'Salvar receita',
      'save_movement': 'Salvar movimentação',
      'receipt_scan': 'Digitalizar comprovante',
      'receipt_scanner_title': 'Digitalizar comprovante',
      'receipt_scanner_help': 'Tire uma foto ou escolha uma imagem. Revise e corrija os dados antes de continuar.',
      'receipt_take_photo': 'Tirar foto',
      'receipt_choose_photo': 'Escolher imagem',
      'receipt_retry_ocr': 'Tentar ler novamente',
      'receipt_merchant': 'Estabelecimento ou descrição',
      'receipt_amount': 'Valor',
      'receipt_date': 'Data do comprovante',
      'receipt_reference': 'Referência (opcional)',
      'receipt_items': 'Detalhes dos produtos (opcional)',
      'receipt_continue_to_expense': 'Continuar para despesa',
      'receipt_select_image': 'Tire uma foto ou escolha uma imagem.',
      'receipt_merchant_required': 'Informe o estabelecimento ou a descrição.',
      'receipt_amount_required': 'Informe um valor válido maior que zero.',
      'receipt_total_not_found':
          'Não foi encontrado um total claro. Confira e informe manualmente.',
      'receipt_ocr_failed': 'Não foi possível ler o comprovante. Você pode preencher os dados manualmente.',
      'receipt_draft_attached':
          'Comprovante pronto; revise os dados da despesa.',
      'receipt_remove': 'Remover comprovante',
      'receipt_view': 'Ver comprovante',
      'receipt_duplicate_title': 'Possível despesa duplicada',
      'receipt_duplicate_message': 'Já existe uma despesa com o mesmo valor e data que pode corresponder a este comprovante.',
      'receipt_duplicate_existing': 'Movimento existente',
      'receipt_save_duplicate': 'Registrar mesmo assim',
      'receipt_attach_existing': 'Anexar comprovante a esta despesa',
      'receipt_has_attachment': 'Já há um comprovante anexado',
      'receipt_attached_existing': 'Comprovante anexado à despesa existente.',
      'backups_title': 'Backups',
      'backups_subtitle': 'Crie, compartilhe e restaure seus backups',
      'backup_create_now': 'Criar backup agora',
      'backup_auto_title': 'Backups automáticos',
      'backup_auto_enabled': 'Backup automático',
      'backup_frequency': 'Frequência',
      'backup_daily': 'Diário',
      'backup_weekly': 'Semanal',
      'backup_monthly': 'Mensal',
      'backup_retention': 'Manter backups automáticos',
      'backup_count': 'backups',
      'backup_last': 'Último backup',
      'backup_next': 'Próximo backup estimado',
      'backup_location': 'Localização',
      'backup_location_local': 'Armazenamento local',
      'backup_too_large': 'O arquivo excede o tamanho máximo permitido.',
      'backup_local_note': 'O backup automático é executado quando você abre ou volta ao MOVA; Android e iOS não garantem um horário exato em segundo plano.',
      'backup_my_files': 'Meus backups',
      'backup_empty': 'Você ainda não tem backups salvos.',
      'backup_manual': 'Manual',
      'backup_automatic': 'Automático',
      'backup_pre_restore': 'Antes de restaurar',
      'backup_save_file': 'Salvar arquivo',
      'backup_share': 'Compartilhar',
      'backup_import': 'Importar backup',
      'backup_restore': 'Restaurar backup',
      'backup_delete': 'Excluir backup',
      'backup_restore_warning': 'A restauração substitui movimentos, contas, metas, categorias, assinaturas, pagamentos, listas e preferências. Sua sessão e credenciais serão mantidas.',
      'backup_before_restore': 'Um backup de segurança será criado primeiro.',
      'backup_created': 'Backup criado com sucesso.',
      'backup_restored': 'Backup restaurado com sucesso.',
      'backup_invalid': 'Arquivo inválido ou danificado.',
      'backup_failed': 'Não foi possível concluir o backup.',
      'backup_incompatible': 'O backup usa uma versão incompatível.',
      'backup_restore_confirm': 'Restaurar e substituir',
      'backup_version': 'Versão do formato',
      'backup_transactions': 'Movimentos',
      'backup_goals': 'Metas',
      'backup_accounts': 'Contas',
      'backup_subscriptions': 'Assinaturas',
      'backup_file_saved': 'Arquivo salvo com sucesso.',
      'backup_delete_confirm':
          'Excluir este backup? Esta ação não pode ser desfeita.',
      'backup_cancelled': 'Restauração cancelada.',
      'create_your_account': 'Crie sua conta',
      'take_control': 'Comece a assumir o controle das suas finanças.',
      'name': 'Nome',
      'enter_name': 'Digite seu nome',
      'enter_email': 'Digite seu e-mail',
      'create_password': 'Crie uma senha',
      'repeat_password': 'Repita sua senha',
      'my_goals': 'Minhas metas',
      'goals_subtitle': 'Transforme seus planos em objetivos',
      'goal_almost_complete': 'Você está perto de alcançar sua meta!',
      'new_goal': 'Nova meta',
      'free_savings': 'Poupança livre',
      'free_savings_help': 'Economize sem uma meta específica',
      'no_goals_yet': 'Você ainda não tem metas',
      'create_goal_savings':
          'Crie uma meta para dar um objetivo às suas economias.',
      'no_goals_home':
          'Você ainda não tem metas. Crie uma para começar a economizar.',
      'add': 'Adicionar',
      'withdraw': 'Retirar',
      'amount': 'Quantidade',
      'close': 'Fechar',
      'my_shopping': 'Minhas compras',
      'current': 'Atuais',
      'history': 'Histórico',
      'new_list': 'Nova lista',
      'no_completed_shopping': 'Ainda não há compras concluídas',
      'plan_first_shopping': 'Planeje sua primeira compra',
      'create_list': 'Criar lista',
      'understood': 'Entendido',
      'something_wrong': 'Algo deu errado',
      'ready': 'Concluído',
      'finance': 'FINANÇAS',
      'your_money': 'Seu dinheiro.\nSuas metas.\nSeu controle.',
      'welcome_subtitle': 'Organize, economize e avance com clareza.',
      'already_account': 'Já tenho uma conta',
      'protected_data': 'Seus dados estão protegidos',
      'logout': 'Sair',
      'close_session': 'Quer sair da sua conta?',
      'notifications_active': 'Notificações ativas',
      'savings_goals': 'Metas de poupança',
      'shopping': 'Compras',
      'view_all': 'Ver tudo',
      'no_summary': 'Não foi possível carregar o resumo',
      'recover_access': 'Recupere seu acesso',
      'new_password': 'Nova senha',
      'confirm_password': 'Confirmar senha',
      'update': 'Atualizar',
      'saving': 'Salvando...',
      'verify': 'Verificar',
      'cancelled': 'Cancelado',
      'account_options': 'Opções da conta',
      'preferences': 'Preferências e opções do MOVA',
      'exit_device': 'Sair da conta neste dispositivo',
      'choose_notifications': 'Escolha quais avisos deseja receber no MOVA.',
      'allow_notifications': 'Permitir notificações',
      'notifications_help': 'Ative ou pause todos os avisos do MOVA',
      'notification_types': 'TIPOS DE AVISO',
      'budget_help': 'Avisos relacionados ao seu orçamento',
      'goals_help': 'Lembretes para avançar em suas metas',
      'shopping_help': 'Lembretes de listas pendentes',
      'my_subscriptions': 'Minhas assinaturas',
      'my_accounts': 'Minhas contas',
      'manage_accounts': 'Gerencie onde seu dinheiro fica',
      'money_by_account': 'Dinheiro por conta',
      'money_by_account_hint':
          'Confira seus saldos e mova dinheiro entre contas.',
      'credit_card_transfer_note': 'O saldo de cartões de crédito é uma dívida. Você pode pagá-la por outra conta, mas não retirá-la como dinheiro.',
      'new_account': 'Nova conta',
      'edit_account': 'Editar conta',
      'accounts_load_error': 'Não foi possível carregar as contas.',
      'account_not_found': 'Conta não encontrada.',
      'accounts_empty': 'Você ainda não tem contas. Adicione uma para começar.',
      'account_name': 'Nome da conta',
      'account_name_hint': 'Ex. BBVA ou Visa',
      'account_type': 'Tipo de conta',
      'account_type_cash': 'Dinheiro',
      'account_type_bank': 'Conta bancária',
      'account_type_debitCard': 'Cartão de débito',
      'account_type_creditCard': 'Cartão de crédito',
      'account_type_savings': 'Conta poupança',
      'initial_balance': 'Saldo inicial disponível',
      'initial_card_debt': 'Dívida atual do cartão',
      'credit_limit': 'Limite de crédito',
      'invalid_initial_balance': 'Informe um saldo inicial válido.',
      'invalid_credit_limit': 'O limite deve cobrir a dívida atual.',
      'institution_optional': 'Instituição (opcional)',
      'institution_hint': 'Ex. BBVA',
      'institution': 'Instituição',
      'last_four_optional': 'Últimos 4 dígitos (opcional)',
      'last_four': 'Últimos 4 dígitos',
      'save_account': 'Salvar conta',
      'account_activity': 'Movimentações e transferências',
      'activity_load_error': 'Não foi possível carregar a atividade.',
      'no_account_activity': 'Ainda não há atividade nesta conta.',
      'account_optional': 'Conta (opcional)',
      'no_account_selected': 'Sem conta associada',
      'available_to_spend': 'Disponível para gastar',
      'money_in_accounts': 'Dinheiro nas contas',
      'credit_debt': 'Dívida dos cartões',
      'credit_available': 'Crédito disponível',
      'allocated_savings_and_goals': 'Separado para economias e metas',
      'general_savings': 'Poupança geral',
      'cash_accounts': 'Dinheiro',
      'bank_accounts': 'Bancos e cartões',
      'inactive': 'Inativa',
      'deactivate_account': 'Desativar conta',
      'transfer': 'Transferência',
      'transfer_money': 'Transferir dinheiro',
      'source_account': 'Conta de origem',
      'destination_account': 'Conta de destino',
      'saving_source_label': 'Conta de origem',
      'saving_destination_label': 'Conta de destino',
      'account_real_balance_label': 'Saldo real',
      'account_available_label': 'Disponível',
      'account_allocated_label': 'Separado',
      'unassigned_savings_account_label': 'Poupança livre sem conta atribuída',
      'date': 'Data',
      'payments_summary': 'Resumo de pagamentos',
      'payments_next_7_days': 'Próximos 7 dias',
      'payments_next_30_days': 'Próximos 30 dias',
      'payments_pending_total': 'Total pendente',
      'money_committed': 'Dinheiro comprometido',
      'add_payment': 'Novo pagamento',
      'edit_payment': 'Editar pagamento',
      'payment_name': 'Nome do pagamento',
      'payment_name_hint': 'Ex. Aluguel, Internet ou cartão Visa',
      'payment_type': 'Tipo de pagamento',
      'payment_type_recurring': 'Pagamento recorrente',
      'payment_type_one_time': 'Pagamento único',
      'payment_type_card': 'Pagamento de cartão',
      'payment_frequency_optional': 'Frequência',
      'payment_due_date': 'Data do pagamento',
      'payment_category': 'Categoria da despesa',
      'payment_account': 'Conta de pagamento (opcional)',
      'payment_card': 'Cartão a pagar',
      'payment_method': 'Forma de pagamento',
      'payment_method_unspecified': 'Não especificado',
      'payment_account_used': 'Conta utilizada',
      'mark_payment_paid': 'Marcar como pago',
      'confirm_payment_title': 'Confirmar pagamento',
      'confirm_payment_message': 'Confirmar o pagamento de {amount}?',
      'find_duplicate_payment':
          'Já existe uma despesa que corresponde a este pagamento.',
      'create_payment_movement': 'Registrar uma nova despesa',
      'payment_saved': 'Pagamento registrado com sucesso.',
      'payment_cancelled': 'Pagamento cancelado.',
      'payment_load_error': 'Não foi possível carregar os pagamentos.',
      'payment_save_error': 'Não foi possível salvar o pagamento.',
      'no_scheduled_payments': 'Você não tem pagamentos pendentes programados.',
      'no_payment_history': 'Ainda não há pagamentos no histórico.',
      'payment_filters': 'Filtros',
      'payment_filter_type': 'Tipo',
      'payment_filter_status': 'Estado',
      'payment_filter_category': 'Categoria',
      'payment_filter_account': 'Conta',
      'payment_filter_all': 'Todos os pagamentos',
      'payment_status_pending': 'Pendente',
      'payment_status_overdue': 'Vencido',
      'payment_status_paid': 'Pago',
      'payment_status_cancelled': 'Cancelado',
      'payment_type_subscription': 'Assinatura',
      'payment_type_filter_recurring': 'Recorrentes',
      'payment_type_filter_card': 'Cartões',
      'payment_type_filter_one_time': 'Pagamentos únicos',
      'payment_type_filter_subscription': 'Assinaturas',
      'payment_time_all': 'Tudo',
      'payment_time_7_days': '7 dias',
      'payment_time_30_days': '30 dias',
      'payment_time_this_month': 'Este mês',
      'payment_time_next_month': 'Próximo mês',
      'payment_overdue_since': 'Venceu em {date}',
      'payment_days_overdue': 'Vencido · {count} dias',
      'payment_not_expense_yet':
          'Pagamentos futuros ainda não são registrados como despesas.',
      'payment_cancel_confirm': 'Cancelar este pagamento programado?',
      'subscriptions': 'Assinaturas',
      'manage_recurring_payments': 'Gerencie seus pagamentos recorrentes',
      'upcoming_payments': 'Próximos pagamentos',
      'upcoming_payments_total': 'Total dos próximos pagamentos',
      'no_active_subscriptions': 'Você não tem assinaturas ativas.',
      'subscription_reminders_help': 'Avisos antes das próximas cobranças',
      'payment_reminders_help': 'Avisos antes dos próximos pagamentos',
      'new_subscription': 'Nova assinatura',
      'subscriptions_load_error': 'Não foi possível carregar as assinaturas.',
      'active_subscriptions': 'Assinaturas ativas',
      'estimated_monthly_spend': 'Gasto mensal estimado',
      'estimated_annual_spend': 'Gasto anual estimado',
      'upcoming_charges': 'Próximas cobranças',
      'no_upcoming_charges': 'Não há cobranças nos próximos 30 dias.',
      'all_subscriptions': 'Todas as assinaturas',
      'subscriptions_empty':
          'Você ainda não tem assinaturas. Adicione a primeira.',
      'days_count': 'Em {count} dias',
      'active': 'Ativa',
      'paused': 'Pausada',
      'next_charge': 'Próxima cobrança',
      'frequency_weekly': 'semana',
      'frequency_biweekly': 'quinzena',
      'frequency_monthly': 'mês',
      'frequency_bimonthly': 'bimestre',
      'frequency_quarterly': 'trimestre',
      'frequency_semiannual': 'semestre',
      'frequency_annual': 'ano',
      'edit_subscription': 'Editar assinatura',
      'subscription_name': 'Nome',
      'subscription_name_hint': 'Ex. Netflix',
      'description_optional': 'Descrição (opcional)',
      'amount_and_currency': 'Valor e moeda',
      'currency': 'Moeda',
      'frequency': 'Frequência',
      'account_or_card': 'Conta ou cartão (opcional)',
      'account_hint': 'Ex. Visa •••• 4582',
      'payment_reminder': 'Lembrete de cobrança',
      'same_day': 'No mesmo dia',
      'days_before': '{count} dias antes',
      'notes_optional': 'Observações (opcional)',
      'required_field': 'Este campo é obrigatório.',
      'amount_must_be_positive': 'Informe um valor maior que zero.',
      'save_error': 'Não foi possível salvar',
      'reminder_schedule_error':
          'A alteração foi salva, mas não foi possível agendar o aviso',
      'save_subscription': 'Salvar assinatura',
      'possible_duplicate': 'Você já registrou essa despesa?',
      'possible_duplicate_body': 'Existe uma despesa com o mesmo valor e categoria na data da cobrança. Associe-a para evitar duplicidade.',
      'link_existing_movement': 'Associar despesa existente',
      'create_expense_anyway': 'Registrar outra despesa',
      'subscription_payment_saved': 'Pagamento da assinatura registrado.',
      'delete_subscription': 'Excluir assinatura',
      'delete_subscription_confirmation': 'A assinatura e seu histórico serão excluídos. As movimentações existentes serão mantidas.',
      'delete': 'Excluir',
      'pause': 'Pausar',
      'reactivate': 'Reativar',
      'cancel_subscription': 'Cancelar assinatura',
      'every': 'A cada',
      'description': 'Descrição',
      'notes': 'Observações',
      'mark_as_paid': 'Marcar como pago',
      'payment_history': 'Histórico de pagamentos',
      'history_load_error': 'Não foi possível carregar o histórico.',
      'no_subscription_payments': 'Ainda não há pagamentos registrados.',
      'paid': 'Pago',
      'month_jan': 'jan',
      'month_feb': 'fev',
      'month_mar': 'mar',
      'month_apr': 'abr',
      'month_may': 'mai',
      'month_jun': 'jun',
      'month_jul': 'jul',
      'month_aug': 'ago',
      'month_sep': 'set',
      'month_oct': 'out',
      'month_nov': 'nov',
      'month_dec': 'dez',
      'Sal de tu cuenta en este dispositivo':
          'Saia da sua conta neste dispositivo',
      'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.':
          'Você ainda não tem metas. Crie uma para começar a economizar.',
      'Crea una meta para darle un objetivo a tus ahorros.':
          'Crie uma meta para dar um objetivo às suas economias.',
      'Gastos por categoría': 'Despesas por categoria',
      'Aún no hay gastos registrados en este periodo.':
          'Ainda não há despesas registradas neste período.',
      'Registra movimientos para obtener recomendaciones.':
          'Registre movimentações para obter recomendações.',
    },
  };

  String text(String key) =>
      _values[locale.languageCode]?[key] ?? _values['es']![key] ?? key;

  String nivoText(String source) {
    final language = locale.languageCode;
    if (language == 'es' || source.isEmpty) return source;

    final exact = _nivoTranslations[language]?[source];
    if (exact != null) return exact;

    final categoryQuestion = RegExp(r'^¿Cuánto gasté en (.+) este mes\?$')
        .firstMatch(source);
    if (categoryQuestion != null) {
      return language == 'en'
          ? 'How much did I spend on ${translate(categoryQuestion[1]!)} this month?'
          : 'Quanto gastei com ${translate(categoryQuestion[1]!)} neste mês?';
    }
    final accountQuestion = RegExp(r'^¿Cuál es el saldo de (.+)\?$')
        .firstMatch(source);
    if (accountQuestion != null) {
      return language == 'en'
          ? 'What is the balance of ${translate(accountQuestion[1]!)}?'
          : 'Qual é o saldo de ${translate(accountQuestion[1]!)}?';
    }
    final goalQuestion = RegExp(r'^¿Cómo va mi meta de (.+)\?$')
        .firstMatch(source);
    if (goalQuestion != null) {
      return language == 'en'
          ? 'How is my ${translate(goalQuestion[1]!)} goal progressing?'
          : 'Como está o progresso da minha meta ${translate(goalQuestion[1]!)}?';
    }
    final balance = RegExp(r'^Tu saldo disponible actualmente es de (.+)\.$')
        .firstMatch(source);
    if (balance != null) {
      return language == 'en'
          ? 'Your current available balance is ${balance[1]}.'
          : 'Seu saldo disponível atual é ${balance[1]}.';
    }
    final transaction = RegExp(
      r'^(.+) has (gastado|recibido) (.+?)(?: en (.+))?\.$',
    ).firstMatch(source);
    if (transaction != null) {
      final period = _nivoPeriod(transaction[1]!, language);
      final action = transaction[2] == 'gastado'
          ? (language == 'en' ? 'you spent' : 'você gastou')
          : (language == 'en' ? 'you received' : 'você recebeu');
      final category = transaction[4];
      return language == 'en'
          ? '$period $action ${transaction[3]}${category == null ? '' : ' on ${translate(category)}'}.'
          : '$period $action ${transaction[3]}${category == null ? '' : ' com ${translate(category)}'}.';
    }
    final comparison = RegExp(
      r'^(.+)\. Comparado con el periodo anterior: (.+) de diferencia\.$',
    ).firstMatch(source);
    if (comparison != null) {
      return '${nivoText('${comparison[1]}.')} '
          '${language == 'en' ? 'Compared with the previous period' : 'Em comparação com o período anterior'}: '
          '${comparison[2]} ${language == 'en' ? 'difference' : 'de diferença'}.';
    }
    final noCategoryExpenses = RegExp(
      r'^No encontré gastos de (.+) para (.+)\.$',
    ).firstMatch(source);
    if (noCategoryExpenses != null) {
      return language == 'en'
          ? 'I found no ${_nivoSubject(noCategoryExpenses[1]!, language)} for ${_nivoPeriod(noCategoryExpenses[2]!, language)}.'
          : 'Não encontrei ${_nivoSubject(noCategoryExpenses[1]!, language)} para ${_nivoPeriod(noCategoryExpenses[2]!, language)}.';
    }
    final balanceGoal = RegExp(
      r'^Llevas (.+) de (.+) para tu meta (.+) \((.+)%\)\.$',
    ).firstMatch(source);
    if (balanceGoal != null) {
      return language == 'en'
          ? 'You have saved ${balanceGoal[1]} of ${balanceGoal[2]} toward your ${balanceGoal[3]} goal (${balanceGoal[4]}%).'
          : 'Você juntou ${balanceGoal[1]} de ${balanceGoal[2]} para sua meta ${balanceGoal[3]} (${balanceGoal[4]}%).';
    }
    final allGoals = RegExp(r'^Tienes (\d+) metas?: (.+)\.$')
        .firstMatch(source);
    if (allGoals != null) {
      final details = allGoals[2]!
          .split('; ')
          .map((detail) {
            final goal = RegExp(r'^(.+): (.+) de (.+) \((.+)%\)$')
                .firstMatch(detail);
            if (goal == null) return detail;
            return language == 'en'
                ? '${goal[1]}: ${goal[2]} of ${goal[3]} (${goal[4]}%)'
                : '${goal[1]}: ${goal[2]} de ${goal[3]} (${goal[4]}%)';
          })
          .join('; ');
      final count = allGoals[1];
      return language == 'en'
          ? 'You have $count ${count == '1' ? 'goal' : 'goals'}: $details.'
          : 'Você tem $count ${count == '1' ? 'meta' : 'metas'}: $details.';
    }
    final savingSummary = RegExp(
      r'^Llevas (.+) ahorrados en total\. Hay (.+) sin asignar y (.+) en tus metas\.$',
    ).firstMatch(source);
    if (savingSummary != null) {
      return language == 'en'
          ? 'You have saved ${savingSummary[1]} in total: ${savingSummary[2]} unassigned and ${savingSummary[3]} in your goals.'
          : 'Você já juntou ${savingSummary[1]} no total: ${savingSummary[2]} sem destino e ${savingSummary[3]} nas suas metas.';
    }
    final dailyAverage = RegExp(r'^Tu promedio diario de (.+) es (.+) (.+)\.$')
        .firstMatch(source);
    if (dailyAverage != null) {
      final period = _nivoPeriod(dailyAverage[3]!, language);
      return language == 'en'
          ? 'Your daily average for ${dailyAverage[1]} is ${dailyAverage[2]} $period.'
          : 'Sua média diária de ${dailyAverage[1]} é ${dailyAverage[2]} $period.';
    }
    final withinBudget = RegExp(
      r'^Has gastado (.+) de tu presupuesto de (.+)\. Te quedan (.+) \((.+)%\)\.$',
    ).firstMatch(source);
    if (withinBudget != null) {
      return language == 'en'
          ? 'You have spent ${withinBudget[1]} of your ${withinBudget[2]} budget. You have ${withinBudget[3]} left (${withinBudget[4]}%).'
          : 'Você gastou ${withinBudget[1]} do seu orçamento de ${withinBudget[2]}. Restam ${withinBudget[3]} (${withinBudget[4]}%).';
    }
    final overBudget = RegExp(
      r'^Has superado tu presupuesto de (.+) por (.+) \((.+)% utilizado\)\.$',
    ).firstMatch(source);
    if (overBudget != null) {
      return language == 'en'
          ? 'You exceeded your ${overBudget[1]} budget by ${overBudget[2]} (${overBudget[3]}% used).'
          : 'Você ultrapassou seu orçamento de ${overBudget[1]} em ${overBudget[2]} (${overBudget[3]}% utilizado).';
    }
    final accountPrompt = RegExp(
      r'^¿En cuál cuenta de efectivo quieres registrar el ingreso\? (.+)\.$',
    ).firstMatch(source);
    if (accountPrompt != null) {
      return language == 'en'
          ? 'Which cash account should receive this income? ${accountPrompt[1]}.'
          : 'Em qual conta de dinheiro você quer registrar a receita? ${accountPrompt[1]}.';
    }
    final goalChoicePrompt = RegExp(
      r'^No encontré esa meta\. Elige una de estas: (.+)\.$',
    ).firstMatch(source);
    if (goalChoicePrompt != null) {
      return language == 'en'
          ? 'I couldn’t find that goal. Choose one of these: ${goalChoicePrompt[1]}.'
          : 'Não encontrei essa meta. Escolha uma destas: ${goalChoicePrompt[1]}.';
    }
    final goalQuestionList = RegExp(
      r'^¿De cuál de tus metas quieres consultar el progreso\? (.+)\.$',
    ).firstMatch(source);
    if (goalQuestionList != null) {
      return language == 'en'
          ? 'Which goal would you like to check? ${goalQuestionList[1]}.'
          : 'Qual meta você gostaria de consultar? ${goalQuestionList[1]}.';
    }
    final actionProposal = RegExp(
      r'^Voy a registrar un gasto de (.+) en (.+?)(?: en (.+?))?( con el comprobante analizado)?\. ¿Quieres que lo haga\? Responde sí o no\.$',
    ).firstMatch(source);
    if (actionProposal != null) {
      final merchant = actionProposal[3];
      final receipt = actionProposal[4] != null;
      return language == 'en'
          ? 'I’m going to record an expense of ${actionProposal[1]} in ${actionProposal[2]}${merchant == null ? '' : ' at $merchant'}${receipt ? ' with the scanned receipt' : ''}. Would you like me to do that? Select Yes or No.'
          : 'Vou registrar uma despesa de ${actionProposal[1]} em ${actionProposal[2]}${merchant == null ? '' : ' em $merchant'}${receipt ? ' com o comprovante digitalizado' : ''}. Quer que eu faça isso? Selecione Sim ou Não.';
    }
    final anyNoResults = RegExp(r'^No encontré (.+) para (.+)\.$')
        .firstMatch(source);
    if (anyNoResults != null) {
      return language == 'en'
          ? 'I found no ${anyNoResults[1]} for ${_nivoPeriod(anyNoResults[2]!, language)}.'
          : 'Não encontrei ${anyNoResults[1]} para ${_nivoPeriod(anyNoResults[2]!, language)}.';
    }
    final accountDetails = RegExp(r'^(.+): (.+?)( de deuda)?(?:\. |$)')
        .allMatches(source)
        .toList();
    if (accountDetails.isNotEmpty &&
        accountDetails.map((match) => match[0]!).join() == source) {
      return accountDetails
          .map(
            (match) => language == 'en'
                ? '${match[1]}: ${match[2]}${match[3] == null ? '' : ' in debt'}'
                : '${match[1]}: ${match[2]}${match[3] == null ? '' : ' em dívida'}',
          )
          .join('. ');
    }
    final subscriptionSummary = RegExp(
      r'^Tienes (\d+) suscripciones activas\. Su costo estimado mensual es (.+)\.$',
    ).firstMatch(source);
    if (subscriptionSummary != null) {
      return language == 'en'
          ? 'You have ${subscriptionSummary[1]} active subscriptions. Their estimated monthly cost is ${subscriptionSummary[2]}.'
          : 'Você tem ${subscriptionSummary[1]} assinaturas ativas. O custo mensal estimado é ${subscriptionSummary[2]}.';
    }
    final paymentSummary = RegExp(
      r'^Tus próximos pagos son: (.+)\. Total: (.+)\.$',
    ).firstMatch(source);
    if (paymentSummary != null) {
      final details = paymentSummary[1]!
          .split('; ')
          .map((detail) {
            final payment = RegExp(r'^(.+): (.+) el (\d{2}/\d{2})$')
                .firstMatch(detail);
            if (payment == null) return detail;
            return language == 'en'
                ? '${payment[1]}: ${payment[2]} on ${payment[3]}'
                : '${payment[1]}: ${payment[2]} em ${payment[3]}';
          })
          .join('; ');
      return language == 'en'
          ? 'Your upcoming payments are: $details. Total: ${paymentSummary[2]}.'
          : 'Seus próximos pagamentos são: $details. Total: ${paymentSummary[2]}.';
    }
    if (source.startsWith('No pude preparar el comprobante: ')) {
      final error = source.substring(
        'No pude preparar el comprobante: '.length,
      );
      return language == 'en'
          ? 'I couldn’t prepare the receipt: $error'
          : 'Não consegui preparar o comprovante: $error';
    }
    final operationError = RegExp(
      r'^No pude completar la operación: (.+)\. No se confirmó ningún cambio\.$',
    ).firstMatch(source);
    if (operationError != null) {
      return language == 'en'
          ? 'I couldn’t complete the operation: ${operationError[1]}. No changes were confirmed.'
          : 'Não consegui concluir a operação: ${operationError[1]}. Nenhuma alteração foi confirmada.';
    }

    final exactFragment = _translateNivoFragments(source, language);
    return exactFragment == source ? translate(source) : exactFragment;
  }

  String _nivoSubject(String source, String language) {
    if (source == 'ingresos') return language == 'en' ? 'income' : 'receitas';
    if (source.startsWith('gastos de ')) {
      return language == 'en'
          ? '${source.substring('gastos de '.length)} expenses'
          : 'despesas de ${source.substring('gastos de '.length)}';
    }
    if (source.startsWith('gastos en ')) {
      return language == 'en'
          ? 'expenses at ${source.substring('gastos en '.length)}'
          : 'despesas em ${source.substring('gastos en '.length)}';
    }
    return language == 'en' ? 'expenses' : 'despesas';
  }

  String _translateNivoFragments(String source, String language) {
    const fragments = {
      'en': {
        'Comparado con el periodo anterior:':
            'Compared with the previous period:',
        'de diferencia.': ' difference.',
        'Tu promedio diario de': 'Your daily average for',
        ' es ': ' is ',
        'Has gastado ': 'You spent ',
        ' de tu presupuesto de ': ' of your budget of ',
        '. Te quedan ': '. You have ',
        'Has superado tu presupuesto de ': 'You exceeded your budget of ',
        ' por ': ' by ',
        ' utilizado).': ' used).',
        'No encontré esa cuenta. ¿Qué cuenta quieres consultar?': 'I couldn’t find that account. Which account would you like to check?',
        'No encontré esa meta. ¿Cuál de tus metas quieres consultar?': 'I couldn’t find that goal. Which of your goals would you like to check?',
        'No entendí la consulta. ¿Puedes darme un poco más de detalle?':
            'I didn’t understand that. Could you give me a little more detail?',
        'No tienes metas creadas todavía. Crea una meta antes de aportar.': 'You haven’t created any goals yet. Create a goal before adding savings.',
        '¿En qué categoría quieres registrarlo? No asignaré una categoría que no hayas indicado.': 'Which category should I use? I won’t assign one you haven’t specified.',
        '¿Cuál es el monto objetivo de la meta?': 'What is the goal amount?',
        '¿Qué importe quieres registrar?':
            'What amount would you like to record?',
        '¿En cuál cuenta de efectivo quieres registrar el ingreso?':
            'Which cash account should receive this income?',
        '¿A cuál de tus metas quieres agregar el dinero?':
            'Which of your goals should receive this money?',
        '¿Cómo quieres llamar a la meta?':
            'What would you like to name the goal?',
        '¿Qué producto quieres agregar?': 'What product would you like to add?',
        'De acuerdo, no hice ningún cambio.':
            'Okay, I didn’t make any changes.',
        'Responde “sí” para confirmar o “no” para cancelar.':
            'Select “Yes” to confirm or “No” to cancel.',
        'No registré el gasto porque confirmaste que es el mismo movimiento existente.': 'I didn’t record the expense because you confirmed it matches an existing transaction.',
        '¿Es el mismo movimiento? Responde “sí” para no duplicarlo o “no” para continuar.': 'Is this the same transaction? Select “Yes” to avoid a duplicate or “No” to continue.',
      },
      'pt': {
        'Comparado con el periodo anterior:':
            'Em comparação com o período anterior:',
        'de diferencia.': ' de diferença.',
        'Tu promedio diario de': 'Sua média diária de',
        ' es ': ' é ',
        'Has gastado ': 'Você gastou ',
        ' de tu presupuesto de ': ' do seu orçamento de ',
        '. Te quedan ': '. Restam ',
        'Has superado tu presupuesto de ': 'Você ultrapassou seu orçamento de ',
        ' por ': ' em ',
        ' utilizado).': ' utilizado).',
        'No encontré esa cuenta. ¿Qué cuenta quieres consultar?':
            'Não encontrei essa conta. Qual conta você gostaria de consultar?',
        'No encontré esa meta. ¿Cuál de tus metas quieres consultar?': 'Não encontrei essa meta. Qual das suas metas você gostaria de consultar?',
        'No entendí la consulta. ¿Puedes darme un poco más de detalle?':
            'Não entendi. Você pode dar mais detalhes?',
        'No tienes metas creadas todavía. Crea una meta antes de aportar.': 'Você ainda não criou metas. Crie uma antes de adicionar economias.',
        '¿En qué categoría quieres registrarlo? No asignaré una categoría que no hayas indicado.': 'Em qual categoria devo registrar? Não vou escolher uma categoria que você não indicou.',
        '¿Cuál es el monto objetivo de la meta?': 'Qual é o valor da meta?',
        '¿Qué importe quieres registrar?': 'Qual valor você quer registrar?',
        '¿En cuál cuenta de efectivo quieres registrar el ingreso?':
            'Em qual conta de dinheiro você quer registrar a receita?',
        '¿A cuál de tus metas quieres agregar el dinero?':
            'A qual das suas metas você quer adicionar esse dinheiro?',
        '¿Cómo quieres llamar a la meta?': 'Que nome você quer dar à meta?',
        '¿Qué producto quieres agregar?': 'Qual produto você quer adicionar?',
        'De acuerdo, no hice ningún cambio.':
            'Tudo bem, não fiz nenhuma alteração.',
        'Responde “sí” para confirmar o “no” para cancelar.':
            'Selecione “Sim” para confirmar ou “Não” para cancelar.',
        'No registré el gasto porque confirmaste que es el mismo movimiento existente.':
            'Não registrei a despesa porque você confirmou que ela já existe.',
        '¿Es el mismo movimiento? Responde “sí” para no duplicarlo o “no” para continuar.': 'É a mesma movimentação? Selecione “Sim” para evitar duplicá-la ou “Não” para continuar.',
      },
    };
    return fragments[language]![source] ?? source;
  }

  String _nivoPeriod(String source, String language) {
    const periods = {
      'hoy': ['Today', 'Hoje'],
      'esta semana': ['This week', 'Esta semana'],
      'la semana pasada': ['Last week', 'Na semana passada'],
      'este mes': ['This month', 'Neste mês'],
      'el mes pasado': ['Last month', 'No mês passado'],
      'este ano': ['This year', 'Neste ano'],
      'el año pasado': ['Last year', 'No ano passado'],
      'ese dia': ['That day', 'Nesse dia'],
      'los proximos 7 dias': ['the next 7 days', 'os próximos 7 dias'],
      'los proximos 30 dias': ['the next 30 days', 'os próximos 30 dias'],
    };
    final normalized = source
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    for (final entry in periods.entries) {
      if (normalized == entry.key) return entry.value[language == 'en' ? 0 : 1];
    }
    return source;
  }

  static const _nivoTranslations = <String, Map<String, String>>{
    'en': {
      'Tu asistente financiero local': 'Your local financial assistant',
      'Privado': 'Private',
      'ASISTENTE FINANCIERO': 'FINANCIAL ASSISTANT',
      'Elige una consulta para empezar': 'Choose a question to get started',
      'Hola, soy Nivo': 'Hi, I’m Nivo',
      'Puedo ayudarte a entender tus finanzas. Pregúntame sobre tus movimientos, metas o próximos pagos.': 'I can help you understand your finances. Ask me about your transactions, goals, or upcoming payments.',
      'Prueba preguntando': 'Try asking',
      'Puedes consultar también:': 'You can also ask:',
      'Nivo está preparando una respuesta': 'Nivo is preparing a response',
      'Nivo está pensando…': 'Nivo is thinking…',
      'No pude cargar más opciones por ahora.':
          'I couldn’t load more options right now.',
      'No pude consultar tus datos en este momento. Inténtalo de nuevo.':
          'I couldn’t check your data right now. Please try again.',
      'Preparé el comprobante analizado para que revises el registro.':
          'I prepared the scanned receipt for you to review.',
      'No encontré datos financieros todavía.':
          'I couldn’t find any financial data yet.',
      'Todavía no tienes movimientos registrados.':
          'You don’t have any recorded transactions yet.',
      'Tienes movimientos registrados, pero no hay saldo disponible en tus cuentas activas.': 'You have recorded transactions, but no available balance in your active accounts.',
      'Aún no tienes ahorro registrado.':
          'You haven’t recorded any savings yet.',
      'Aún no tienes metas registradas.': 'You haven’t created any goals yet.',
      'No tienes suscripciones activas.': 'You have no active subscriptions.',
      'No encontré pagos próximos en ese periodo.':
          'I found no upcoming payments for that period.',
      'No encontré esa cuenta. ¿Qué cuenta quieres consultar?': 'I couldn’t find that account. Which account would you like to check?',
      'No encontré esa meta. ¿Cuál de tus metas quieres consultar?': 'I couldn’t find that goal. Which of your goals would you like to check?',
      'No entendí la consulta. ¿Puedes darme un poco más de detalle?':
          'I didn’t understand that. Could you give me a little more detail?',
      'No tienes metas creadas todavía. Crea una meta antes de aportar.': 'You haven’t created any goals yet. Create a goal before adding savings.',
      '¿Cuál es el monto objetivo de la meta?': 'What is the goal amount?',
      '¿Qué importe quieres registrar?':
          'What amount would you like to record?',
      '¿En qué categoría quieres registrarlo? No asignaré una categoría que no hayas indicado.': 'Which category should I use? I won’t assign one you haven’t specified.',
      '¿A cuál de tus metas quieres agregar el dinero?':
          'Which of your goals should receive this money?',
      '¿Cómo quieres llamar a la meta?':
          'What would you like to name the goal?',
      '¿Qué producto quieres agregar?': 'What product would you like to add?',
      'De acuerdo, no hice ningún cambio.': 'Okay, I didn’t make any changes.',
      'Responde “sí” para confirmar o “no” para cancelar.':
          'Select “Yes” to confirm or “No” to cancel.',
      'No registré el gasto porque confirmaste que es el mismo movimiento existente.': 'I didn’t record the expense because you confirmed it matches an existing transaction.',
      '¿Es el mismo movimiento? Responde “sí” para no duplicarlo o “no” para continuar.': 'Is this the same transaction? Select “Yes” to avoid a duplicate or “No” to continue.',
      'No ejecutaré una acción destructiva a partir de una frase detectada. La eliminación de registros no está habilitada en Nivo.': 'I won’t perform a destructive action based on detected text. Deleting records is not available in Nivo.',
      'No encontré esa meta en tus datos actuales.':
          'I couldn’t find that goal in your current data.',
      'No pude preparar esa acción. ¿Puedes darme más detalles?':
          'I couldn’t prepare that action. Could you provide more details?',
      '¿Qué cuenta quieres usar?': 'Which account would you like to use?',
      '¿A cuál lista quieres agregarlo?':
          'Which list would you like to add it to?',
      '¿De cuál de tus metas quieres consultar el progreso?':
          'Which goal would you like to check?',
      'Puedes omitirla respondiendo “sin cuenta”.':
          'You can skip it by selecting “No account”.',
      'No pude completar la operación:': 'I couldn’t complete the operation:',
      'No se confirmó ningún cambio.': 'No changes were confirmed.',
      'Todavía no tienes un presupuesto configurado.':
          'You haven’t set up a budget yet.',
      '¿Cuánto gasté este mes?': 'How much did I spend this month?',
      '¿Cuánto tengo disponible?': 'How much money do I have available?',
      '¿Cómo van mis metas?': 'How are my goals going?',
      '¿Qué pagos tengo próximos?': 'What payments are coming up?',
      '¿Cuánto gasté este mes comparado con el anterior?':
          'How does this month’s spending compare with last month?',
      '¿Cuánto gasté en promedio este mes?':
          'What was my average spending this month?',
      '¿Cuánto llevo ahorrado?': 'How much have I saved?',
      '¿Cuánto dinero tengo?': 'How much money do I have?',
      '¿Cuánto recibí este mes?': 'How much income did I receive this month?',
      '¿Qué pagos tengo esta semana?': 'What payments do I have this week?',
      '¿Qué pagos tengo próximamente?': 'What payments are coming up?',
      '¿Cuáles son mis suscripciones activas?':
          'What are my active subscriptions?',
      'Sí': 'Yes',
      'No': 'No',
      'Cancelar': 'Cancel',
    },
    'pt': {
      'Tu asistente financiero local': 'Seu assistente financeiro local',
      'Privado': 'Privado',
      'ASISTENTE FINANCIERO': 'ASSISTENTE FINANCEIRO',
      'Elige una consulta para empezar': 'Escolha uma pergunta para começar',
      'Hola, soy Nivo': 'Olá, eu sou o Nivo',
      'Puedo ayudarte a entender tus finanzas. Pregúntame sobre tus movimientos, metas o próximos pagos.': 'Posso ajudar você a entender suas finanças. Pergunte sobre suas movimentações, metas ou próximos pagamentos.',
      'Prueba preguntando': 'Experimente perguntar',
      'Puedes consultar también:': 'Você também pode consultar:',
      'Nivo está preparando una respuesta': 'Nivo está preparando uma resposta',
      'Nivo está pensando…': 'Nivo está pensando…',
      'No pude cargar más opciones por ahora.':
          'Não consegui carregar mais opções agora.',
      'No pude consultar tus datos en este momento. Inténtalo de nuevo.':
          'Não consegui consultar seus dados agora. Tente novamente.',
      'Preparé el comprobante analizado para que revises el registro.':
          'Preparei o comprovante analisado para você revisar o registro.',
      'No encontré datos financieros todavía.':
          'Ainda não encontrei dados financeiros.',
      'Todavía no tienes movimientos registrados.':
          'Você ainda não tem movimentações registradas.',
      'Tienes movimientos registrados, pero no hay saldo disponible en tus cuentas activas.': 'Você tem movimentações registradas, mas não há saldo disponível nas suas contas ativas.',
      'Aún no tienes ahorro registrado.':
          'Você ainda não tem economias registradas.',
      'Aún no tienes metas registradas.': 'Você ainda não criou metas.',
      'No tienes suscripciones activas.': 'Você não tem assinaturas ativas.',
      'No encontré pagos próximos en ese periodo.':
          'Não encontrei pagamentos próximos nesse período.',
      'No encontré esa cuenta. ¿Qué cuenta quieres consultar?':
          'Não encontrei essa conta. Qual conta você gostaria de consultar?',
      'No encontré esa meta. ¿Cuál de tus metas quieres consultar?': 'Não encontrei essa meta. Qual das suas metas você gostaria de consultar?',
      'No entendí la consulta. ¿Puedes darme un poco más de detalle?':
          'Não entendi. Você pode dar mais detalhes?',
      'No tienes metas creadas todavía. Crea una meta antes de aportar.':
          'Você ainda não criou metas. Crie uma antes de adicionar economias.',
      '¿Cuál es el monto objetivo de la meta?': 'Qual é o valor da meta?',
      '¿Qué importe quieres registrar?': 'Qual valor você quer registrar?',
      '¿En qué categoría quieres registrarlo? No asignaré una categoría que no hayas indicado.': 'Em qual categoria devo registrar? Não vou escolher uma categoria que você não indicou.',
      '¿A cuál de tus metas quieres agregar el dinero?':
          'A qual das suas metas você quer adicionar esse dinheiro?',
      '¿Cómo quieres llamar a la meta?': 'Que nome você quer dar à meta?',
      '¿Qué producto quieres agregar?': 'Qual produto você quer adicionar?',
      'De acuerdo, no hice ningún cambio.':
          'Tudo bem, não fiz nenhuma alteração.',
      'Responde “sí” para confirmar o “no” para cancelar.':
          'Selecione “Sim” para confirmar ou “Não” para cancelar.',
      'No registré el gasto porque confirmaste que es el mismo movimiento existente.':
          'Não registrei a despesa porque você confirmou que ela já existe.',
      '¿Es el mismo movimiento? Responde “sí” para no duplicarlo o “no” para continuar.': 'É a mesma movimentação? Selecione “Sim” para evitar duplicá-la ou “Não” para continuar.',
      'No ejecutaré una acción destructiva a partir de una frase detectada. La eliminación de registros no está habilitada en Nivo.': 'Não farei uma ação destrutiva com base em uma frase detectada. A exclusão de registros não está disponível no Nivo.',
      'No encontré esa meta en tus datos actuales.':
          'Não encontrei essa meta nos seus dados atuais.',
      'No pude preparar esa acción. ¿Puedes darme más detalles?':
          'Não consegui preparar essa ação. Você pode dar mais detalhes?',
      '¿Qué cuenta quieres usar?': 'Qual conta você gostaria de usar?',
      '¿A cuál lista quieres agregarlo?':
          'A qual lista você gostaria de adicionar?',
      '¿De cuál de tus metas quieres consultar el progreso?':
          'Qual meta você gostaria de consultar?',
      'Puedes omitirla respondiendo “sin cuenta”.':
          'Você pode ignorá-la selecionando “Sem conta”.',
      'No pude completar la operación:': 'Não consegui concluir a operação:',
      'No se confirmó ningún cambio.': 'Nenhuma alteração foi confirmada.',
      'Todavía no tienes un presupuesto configurado.':
          'Você ainda não configurou um orçamento.',
      '¿Cuánto gasté este mes?': 'Quanto gastei neste mês?',
      '¿Cuánto tengo disponible?': 'Quanto tenho disponível?',
      '¿Cómo van mis metas?': 'Como estão minhas metas?',
      '¿Qué pagos tengo próximos?': 'Quais pagamentos estão próximos?',
      '¿Cuánto gasté este mes comparado con el anterior?':
          'Quanto gastei neste mês em comparação com o mês passado?',
      '¿Cuánto gasté en promedio este mes?':
          'Qual foi meu gasto médio neste mês?',
      '¿Cuánto llevo ahorrado?': 'Quanto já economizei?',
      '¿Cuánto dinero tengo?': 'Quanto dinheiro eu tenho?',
      '¿Cuánto recibí este mes?': 'Quanto recebi neste mês?',
      '¿Qué pagos tengo esta semana?': 'Quais pagamentos tenho nesta semana?',
      '¿Qué pagos tengo próximamente?': 'Quais pagamentos estão próximos?',
      '¿Cuáles son mis suscripciones activas?':
          'Quais são minhas assinaturas ativas?',
      'Sí': 'Sim',
      'No': 'Não',
      'Cancelar': 'Cancelar',
    },
  };

  String _canonicalSpanish(String source) {
    for (final entry in _values['es']!.entries) {
      if (entry.key == source || entry.value == source) return entry.value;
    }
    for (final language in ['en', 'pt']) {
      for (final entry in _values[language]!.entries) {
        if (entry.value == source && _values['es']!.containsKey(entry.key)) {
          return _values['es']![entry.key]!;
        }
      }
      for (final entry in _phraseTranslations[language]!.entries) {
        if (entry.value == source) return entry.key;
      }
    }
    return source;
  }

  String translate(String source) {
    if (source.isEmpty) return source;
    source = _canonicalSpanish(source);
    if (locale.languageCode == 'es') return source;
    String? key;
    for (final entry in _values['es']!.entries) {
      if (entry.key == source || entry.value == source) {
        key = entry.key;
        break;
      }
    }
    if (key != null && _values[locale.languageCode]?.containsKey(key) == true) {
      return text(key);
    }
    final phrases = _phraseTranslations[locale.languageCode];
    if (phrases != null) {
      final exact = phrases[source];
      if (exact != null) return exact;
      var translated = source;
      final ordered = phrases.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));
      for (final entry in ordered) {
        translated = translated.replaceAll(entry.key, entry.value);
      }
      if (translated != source) return translated;
    }
    return source;
  }

  static const _phraseTranslations = <String, Map<String, String>>{
    'en': {
      'No se pudo cargar': 'Could not load',
      'No se pudieron cargar': 'Could not load',
      'No hay movimientos': 'There are no movements',
      'Aún no tienes movimientos registrados':
          'You have no recorded movements yet',
      'Aún no tienes metas': 'You have no goals yet',
      'Crea una meta': 'Create a goal',
      'Meta actual': 'Current goal',
      'Dinero disponible': 'Available money',
      'Movimientos recientes': 'Recent movements',
      'Ver todos': 'View all',
      'Gastos por categoría': 'Expenses by category',
      'Aún no hay gastos registrados': 'No expenses recorded',
      'Registra movimientos': 'Record movements',
      'Ingresos registrados': 'Recorded income',
      'Tus gastos superan tus ingresos': 'Your expenses exceed your income',
      'Crear nueva meta': 'Create new goal',
      'Información de la meta': 'Goal information',
      'Elige un icono': 'Choose an icon',
      'Agregar imagen': 'Add image',
      'Modificar ahorro': 'Edit savings',
      'Retirar de la meta': 'Withdraw from goal',
      'Historial de la meta': 'Goal history',
      'No se puede deshacer': 'This cannot be undone',
      'Registrar gasto': 'Record expense',
      'Total estimado': 'Estimated total',
      'La lista está vacía': 'The list is empty',
      'Crea una contraseña': 'Create a password',
      'Mínimo 8 caracteres': 'At least 8 characters',
      'Verificando': 'Verifying',
      'Cerrar': 'Close',
      'Cancelar': 'Cancel',
      'Guardar': 'Save',
      'Eliminar': 'Delete',
      'Retirar': 'Withdraw',
      'Compartir': 'Share',
      'No se pudo actualizar el ahorro': 'Could not update savings',
      'Ahorro libre': 'Free savings',
      'Ahorra sin tener una meta específica': 'Save without a specific goal',
      'Ahorro retirado correctamente.': 'Savings withdrawn successfully.',
      'Ahorro agregado correctamente.': 'Savings added successfully.',
      'Retirar ahorro libre': 'Withdraw free savings',
      'Agregar ahorro libre': 'Add free savings',
      'Cantidad': 'Amount',
      'Cantidad ahorrada': 'Saved amount',
      'Disponible': 'Available',
      'Ahorrado': 'Saved',
      'A la cuenta': 'To account',
      'En la cuenta': 'In account',
      'Selecciona una cuenta.': 'Select an account.',
      'No hay cuentas activas en la moneda principal.':
          'There are no active accounts in the primary currency.',
      'Elige cuánto deseas retirar y a qué cuenta devolverlo.':
          'Choose how much to withdraw and which account to return it to.',
      'Elige de qué cuenta apartar el dinero, sin asociarlo a una meta.': 'Choose which account to move money from, without assigning it to a goal.',
      'Sin icono': 'No icon',
      'RESUMEN DE AHORRO': 'SAVINGS SUMMARY',
      'Disponible en la meta': 'Available in goal',
      'Todavía no hay movimientos en esta meta.':
          'There are no movements in this goal yet.',
      'Ahorro agregado': 'Savings added',
      'No se pudo crear la meta': 'Could not create the goal',
      'No se pudo retirar el dinero. Intenta nuevamente.':
          'Could not withdraw the money. Try again.',
      'Nombre de la meta': 'Goal name',
      'Ahorro inicial': 'Initial savings',
      'Se eliminarán también sus productos.':
          'Its products will also be deleted.',
      'Cuando finalices una lista aparecerá aquí.':
          'When you finish a list, it will appear here.',
      'Organiza tus productos y controla cuánto vas a gastar.':
          'Organize your products and track how much you will spend.',
      'Tu lista está vacía': 'Your list is empty',
      'Agrega productos para calcular tu compra.':
          'Add products to calculate your purchase.',
      'Crear lista': 'Create list',
      'Nueva lista': 'New list',
      'Renombrar lista': 'Rename list',
      'Nombre de la lista': 'List name',
      'Producto': 'Product',
      'Agregar producto': 'Add product',
      'Editar producto': 'Edit product',
      'Completa el producto con valores válidos.':
          'Complete the product with valid values.',
      'Monto inválido': 'Invalid amount',
      'Sin fecha': 'No date',
      'El precio se aplicará por:': 'The price will be applied per:',
      'Planifica tu próxima compra.': 'Plan your next purchase.',
      'Error de acceso': 'Access error',
      'Tus datos están protegidos': 'Your data is protected',
      'Contraseña actualizada. Ya puedes iniciar sesión.':
          'Password updated. You can now log in.',
      'No existe una cuenta con ese correo':
          'There is no account with that email',
      'No se pudo verificar tu identidad': 'Could not verify your identity',
      'Recupera tu acceso': 'Recover your access',
      'Identidad verificada': 'Identity verified',
      'Descripción': 'Description',
      'Fecha': 'Date',
      'El ingreso se agregará a tu saldo.':
          'The income will be added to your balance.',
      'Ingresa un monto válido mayor que cero':
          'Enter a valid amount greater than zero',
      'Escribe una descripción': 'Write a description',
      'Ingreso guardado correctamente': 'Income saved successfully',
      'Gasto guardado correctamente': 'Expense saved successfully',
      'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.':
          'You have no goals yet. Create one to start saving toward a goal.',
      'Sal de tu cuenta en este dispositivo':
          'Sign out of your account on this device',
      'No se pudo cargar el historial': 'Could not load history',
      'Esta acción no se puede deshacer.': 'This action cannot be undone.',
      'El ahorro inicial no puede superar la meta':
          'Initial savings cannot exceed the goal',
      'Dale un propósito a tu ahorro': 'Give your savings a purpose',
      'Aún no hay gastos registrados en este periodo.':
          'There are no expenses recorded in this period.',
      'Aún no hay ingresos registrados en este periodo.':
          'There is no income recorded in this period.',
      'No se pudo cargar el análisis': 'Could not load the analysis',
      'No se pudo cargar el resumen': 'Could not load the summary',
      'Actualizado el 23 de septiembre de 2026': 'Updated September 23, 2026',
      'INFORMACIÓN LEGAL DE MOVA': 'MOVA LEGAL INFORMATION',
      'CONTENIDO': 'CONTENTS',
      'secciones': 'sections',
      'Acepto los ': 'I accept the ',
      'aviso de privacidad': 'privacy notice',
      'Contraseña débil': 'Weak password',
      'Aceptación requerida': 'Acceptance required',
      'Revisa tu nombre, correo y contraseña.':
          'Check your name, email, and password.',
      'Revisa tu correo y contraseña e inténtalo nuevamente.':
          'Check your email and password and try again.',
      'No fue posible iniciar sesión.': 'Could not log in.',
      'Escribe tu correo electrónico': 'Enter your email',
      'Usa mínimo 8 caracteres': 'Use at least 8 characters',
      'Administra tu información personal': 'Manage your personal information',
      'Nombre': 'Name',
      'Define cuánto quieres gastar': 'Set how much you want to spend',
      'Protege tu información': 'Protect your information',
      'Importar datos': 'Import data',
      'Importa información existente': 'Import existing information',
      'Consulta cómo se tratan tus datos': 'Learn how your data is handled',
      'Cerrar sesión': 'Log out',
      'Eliminar cuenta': 'Delete account',
      'Esta acción es permanente.': 'This action is permanent.',
      'Se eliminarán tu cuenta, movimientos, metas, listas y configuraciones. No podrás recuperar estos datos.': 'Your account, movements, goals, lists, and settings will be deleted. You will not be able to recover this data.',
      'No se pudo eliminar la cuenta. Intenta nuevamente.':
          'Could not delete the account. Please try again.',
      'Más': 'More',
      'Importar respaldo': 'Import backup',
      'El archivo no tiene un formato válido': 'The file format is invalid',
      'Elige qué recordatorios quieres recibir':
          'Choose which reminders you want to receive',
      'Avisos relacionados con tu límite mensual':
          'Alerts related to your monthly limit',
      'Lista de compras': 'Shopping list',
      'Versión 1.0.0  ·  Finanzas personales':
          'Version 1.0.0  ·  Personal finance',
      'Biometría no disponible': 'Biometrics unavailable',
      'Verificación no completada': 'Verification not completed',
      'Elige una sola forma de proteger tu sesión':
          'Choose one way to protect your session',
      'Huella o biometría': 'Fingerprint or biometrics',
      'Usa el sensor del dispositivo': 'Use the device sensor',
      'Números (PIN)': 'Numbers (PIN)',
      'Crea un código de 4 a 8 dígitos': 'Create a 4 to 8 digit code',
      'Desactivar protección': 'Disable protection',
      'Crear PIN': 'Create PIN',
      'PIN de 4 a 8 dígitos': '4 to 8 digit PIN',
      'Ingresa un presupuesto válido': 'Enter a valid budget',
      'Presupuesto actualizado': 'Budget updated',
      'Controla tus gastos sin perder de vista tu límite':
          'Track your spending without losing sight of your limit',
      'Se reinicia cada lunes y considera tus gastos de esta semana.':
          'It resets every Monday and considers your spending for this week.',
      'Se reinicia el primer día de cada mes.':
          'It resets on the first day of each month.',
      'Nombre de la categoría': 'Category name',
      'Icono o emoji': 'Icon or emoji',
      'Puedes usar un emoji para identificarla más rápido.':
          'You can use an emoji to identify it faster.',
      'Pega aquí el JSON exportado desde MOVA. Tus datos actuales no se eliminarán.': 'Paste the JSON exported from MOVA here. Your current data will not be deleted.',
      'MOVA está diseñada con un enfoque offline-first. Tus datos principales se mantienen en tu dispositivo.': 'MOVA is designed with an offline-first approach. Your main data stays on your device.',
      'Organiza ingresos, gastos, metas y compras en un solo espacio, de forma clara y sencilla.': 'Organize income, expenses, goals, and purchases in one clear, simple space.',
      'Lee estas condiciones para conocer el uso responsable de MOVA.':
          'Read these terms to learn about responsible use of MOVA.',
      'Consulta qué información se guarda y cómo puedes administrar tus datos.':
          'Learn what information is stored and how you can manage your data.',
      'Límite mensual': 'Monthly limit',
      'Quitar límite': 'Remove limit',
      'Moneda de la aplicación': 'App currency',
      'Esa categoría ya existe para ese tipo':
          'That category already exists for this type',
      'Aún no tienes categorías personalizadas':
          'You have no custom categories yet',
      '¿Qué tipo de movimiento será?': 'What type of movement will it be?',
      'Crear categoría': 'Create category',
      'Nueva categoría': 'New category',
      'Personaliza tus movimientos para encontrarlos fácilmente':
          'Customize your movements to find them easily',
      'FINANZAS': 'FINANCES',
      'APLICACIÓN': 'APPLICATION',
      'DATOS': 'DATA',
      'INFORMACIÓN': 'INFORMATION',
      'CUENTA': 'ACCOUNT',
      'Administra tus categorías de ingresos y gastos':
          'Manage your income and expense categories',
      'Organiza productos, calcula y registra tus compras':
          'Organize products, calculate, and record your purchases',
      'Gestiona tus recordatorios': 'Manage your reminders',
      'Consulta las condiciones de uso': 'View the terms of use',
      'Acerca de MOVA': 'About MOVA',
      'Exportar datos': 'Export data',
      'Descarga tus movimientos': 'Download your movements',
      'Todo lo que necesitas para controlar MOVA':
          'Everything you need to manage MOVA',
      'Crea una meta para darle un objetivo a tus ahorros.':
          'Create a goal to give your savings a purpose.',
      'Al crear una cuenta y utilizar MOVA confirmas que leíste, comprendiste y aceptas estos términos.': 'By creating an account and using MOVA, you confirm that you have read, understood, and accept these terms.',
      'MOVA es una herramienta de organización financiera personal para registrar ingresos, gastos, metas, presupuestos y listas.': 'MOVA is a personal finance organization tool for recording income, expenses, goals, budgets, and lists.',
      'Eres responsable de mantener la confidencialidad de tu correo y contraseña, así como de la actividad realizada desde tu dispositivo.': 'You are responsible for keeping your email and password confidential, as well as for activity performed from your device.',
      'Los cálculos y análisis son orientativos y dependen de los datos que registres. MOVA no sustituye asesoría financiera profesional.': 'Calculations and analyses are for guidance and depend on the data you enter. MOVA does not replace professional financial advice.',
      'No debes acceder a cuentas ajenas, alterar la aplicación ni utilizar MOVA para actividades ilegales.': 'You must not access other accounts, alter the app, or use MOVA for illegal activities.',
      'MOVA puede guardar tu nombre, correo, contraseña, foto de perfil, movimientos, metas, presupuestos, categorías y listas.': 'MOVA may store your name, email, password, profile photo, movements, goals, budgets, categories, and lists.',
      'Utilizamos esta información para proteger tu cuenta, mostrar tus finanzas, generar resúmenes y conservar tus preferencias.': 'We use this information to protect your account, show your finances, generate summaries, and keep your preferences.',
      'La información financiera de MOVA se almacena localmente en el dispositivo para que puedas utilizar la aplicación.': 'MOVA financial information is stored locally on the device so you can use the app.',
      'Puedes editar o eliminar la información desde las funciones disponibles de MOVA, incluida la eliminación de tu cuenta.': 'You can edit or delete information using MOVA features, including deleting your account.',
      'Tu avance acumulado': 'Your accumulated progress',
      'Registra movimientos para obtener recomendaciones.':
          'Record movements to get recommendations.',
      'Tus gastos superan tus ingresos en':
          'Your expenses exceed your income by',
      'Tu balance positivo es de': 'Your positive balance is',
      'de': 'of',
      'establecidos': 'set',
      'completado': 'completed',
      'Guardando...': 'Saving...',
      'Actualizar': 'Update',
      'Quitar foto': 'Remove photo',
      'Agregar foto de perfil': 'Add profile photo',
      'Cambiar foto de perfil': 'Change profile photo',
      'Agrega una foto para personalizar tu cuenta':
          'Add a photo to personalize your account',
      'Tu foto de perfil': 'Your profile photo',
      'Agregar': 'Add',
      'Antes de continuar': 'Before continuing',
      'Aporte': 'Contribution',
      'Borra tu cuenta y todos sus datos':
          'Delete your account and all its data',
      'Compartir meta': 'Share goal',
      'Compra incompleta': 'Incomplete purchase',
      'Contenido de la copia': 'Backup contents',
      'Copia lista': 'Copy ready',
      'Copiar de nuevo': 'Copy again',
      'Crear QR': 'Create QR',
      'Crear meta': 'Create goal',
      'Cuenta existente': 'Existing account',
      'Define qué necesitas y calcula el costo al instante.':
          'Define what you need and calculate the cost instantly.',
      'Desbloquear': 'Unlock',
      'Editar': 'Edit',
      'Editar información de tu cuenta': 'Edit your account information',
      'Editar nombre': 'Edit name',
      'Ej. 8,000.00': 'E.g. 8,000.00',
      'Ej. Comida, transporte o freelance':
          'E.g. Food, transport, or freelance',
      'Elige un emoji': 'Choose an emoji',
      'Eliminar lista': 'Delete list',
      'Eliminar meta': 'Delete goal',
      'Eliminar producto': 'Delete product',
      'Escribe tu nombre': 'Enter your name',
      'Escribe una cantidad mayor a cero.':
          'Enter an amount greater than zero.',
      'Finalizar': 'Finish',
      'Importar': 'Import',
      'Licencias': 'Licenses',
      'Límite mensual (': 'Monthly limit (',
      'Mensual': 'Monthly',
      'Moneda general de MOVA': 'MOVA default currency',
      'Monto a retirar': 'Amount to withdraw',
      'Monto del aporte': 'Contribution amount',
      'No se pudo abrir el selector de imágenes:':
          'Could not open the image picker:',
      'No se pudo actualizar el ahorro:': 'Could not update savings:',
      'No se pudo cargar el análisis:': 'Could not load the analysis:',
      'No se pudo cargar el historial:': 'Could not load the history:',
      'No se pudo cargar el resumen:': 'Could not load the summary:',
      'No se pudo completar': 'Could not complete',
      'No se pudo guardar la preferencia.': 'Could not save the preference.',
      'El correo electrónico ya está registrado.':
          'This email is already registered.',
      'No se pudo guardar el movimiento:': 'Could not save the movement:',
      'La biometría no está disponible o no está configurada en este dispositivo.':
          'Biometrics are unavailable or not configured on this device.',
      'La verificación fue cancelada.': 'Verification was canceled.',
      'No se pudo verificar tu identidad. Confirma que tienes una huella o rostro registrado en los ajustes del teléfono.': 'Identity verification failed. Confirm that a fingerprint or face is registered in your phone settings.',
      'El sistema biométrico devolvió un error. Verifica la biometría configurada en tu teléfono e inténtalo nuevamente.': 'The biometric system returned an error. Check the biometrics configured on your phone and try again.',
      'Presupuesto excedido': 'Budget exceeded',
      'Precio pendiente': 'Price pending',
      'Precio opcional': 'Optional price',
      'Opcional · JPG, PNG o WebP': 'Optional · JPG, PNG, or WebP',
      'PROGRESO DE LA META': 'GOAL PROGRESS',
      'Permite recibir recordatorios de Mova':
          'Allow receiving reminders from Mova',
      'Por ': 'Per ',
      'Presupuesto ': 'Budget ',
      'QR de aporte': 'Contribution QR',
      'Recordatorios para avanzar en tus metas':
          'Reminders to progress toward your goals',
      'Registrar compra': 'Record purchase',
      'Respaldo local': 'Local backup',
      'Tu información está preparada para guardarse':
          'Your information is ready to be saved',
      'Agrega información de otra copia de MOVA':
          'Add information from another MOVA backup',
      'Solo se importan movimientos válidos. La información existente se conserva.': 'Only valid movements are imported. Existing information is preserved.',
      'Cambiar la moneda no modifica el límite configurado.':
          'Changing the currency does not modify the configured limit.',
      'El archivo se copió al portapapeles. Pégalo en un lugar seguro para conservarlo.': 'The file was copied to the clipboard. Paste it somewhere safe to keep it.',
      'movimientos': 'movements',
      'metas': 'goals',
      'listas': 'lists',
      'Se aplicará a ingresos, gastos, metas, compras y presupuesto. No convierte cantidades existentes.': 'It applies to income, expenses, goals, purchases, and budgets. It does not convert existing amounts.',
      'Tu límite semanal quedó en': 'Your weekly limit is set to',
      'Tu límite mensual quedó en': 'Your monthly limit is set to',
      'Revisa el producto': 'Review the product',
      'Semanal': 'Weekly',
      'Total': 'Total',
      'Tu balance positivo es de ': 'Your positive balance is ',
      'Tu dinero, en movimiento.': 'Your money, in motion.',
      'Usa un nombre fácil de reconocer.': 'Use an easy-to-recognize name.',
      'Versión 1.0.0': 'Version 1.0.0',
      '¿De dónde provino este ingreso?': 'Where did this income come from?',
      '¿Ya tienes una cuenta?': 'Already have an account?',
      'Activar notificaciones': 'Enable notifications',
      'Agrega al menos un producto antes de finalizar.':
          'Add at least one product before finishing.',
      'movimientos importados': 'movements imported',
      'y el ': 'and the ',
      'Verificando...': 'Verifying...',
      'Verificar con huella': 'Verify with fingerprint',
      'Escribe una cantidad mayor a cero': 'Enter an amount greater than zero.',
      'Ingresa un monto mayor que cero': 'Enter an amount greater than zero',
      'Ingresa un correo electrónico válido.': 'Enter a valid email address.',
      'Usa al menos 8 caracteres, una mayúscula, un número o un símbolo.':
          'Use at least 8 characters, one uppercase letter, number, or symbol.',
      'Las contraseñas no coinciden.': 'Passwords do not match.',
      'Debes aceptar los términos y condiciones.':
          'You must accept the terms and conditions.',
      'Términos y condiciones': 'Terms and conditions',
      'Aviso de privacidad': 'Privacy notice',
      'meta activa': 'active goal',
      'metas activas': 'active goals',
      'Retiro': 'Withdrawal',
      'Compra finalizada': 'Purchase completed',
      'Control de compra': 'Purchase tracking',
      'Agregado al carrito': 'Added to cart',
      'Pendiente por comprar': 'Pending purchase',
      'gastado hasta hoy': 'spent today',
      'Sueldo': 'Salary',
      'Freelance': 'Freelance',
      'Inversión': 'Investment',
      'Regalo': 'Gift',
      'Venta': 'Sale',
      'Otro': 'Other',
      'Comida': 'Food',
      'Transporte': 'Transport',
      'Compras': 'Shopping',
      'Hogar': 'Home',
      'Entretenimiento': 'Entertainment',
      'Ahorro': 'Savings',
      'Ahorro sin meta': 'Savings without goal',
      'Otros': 'Others',
      'Aparta una cantidad sin asociarla a una meta.':
          'Set aside an amount without linking it to a goal.',
      'Lista en curso': 'List in progress',
      'No se pudieron cargar los movimientos:': 'Could not load movements:',
      'Las contraseñas no coinciden': 'Passwords do not match',
    },
    'pt': {
      'No se pudo cargar': 'Não foi possível carregar',
      'No se pudieron cargar': 'Não foi possível carregar',
      'No hay movimientos': 'Não há movimentações',
      'Aún no tienes movimientos registrados':
          'Você ainda não tem movimentações registradas',
      'Aún no tienes metas': 'Você ainda não tem metas',
      'Crea una meta': 'Crie uma meta',
      'Meta actual': 'Meta atual',
      'Dinero disponible': 'Dinheiro disponível',
      'Movimientos recientes': 'Movimentações recentes',
      'Ver todos': 'Ver tudo',
      'Gastos por categoría': 'Despesas por categoria',
      'Aún no hay gastos registrados': 'Ainda não há despesas registradas',
      'Registra movimientos': 'Registre movimentações',
      'Crear nueva meta': 'Criar nova meta',
      'Información de la meta': 'Informações da meta',
      'Elige un icono': 'Escolha um ícone',
      'Agregar imagen': 'Adicionar imagem',
      'Modificar ahorro': 'Editar poupança',
      'Retirar de la meta': 'Retirar da meta',
      'Historial de la meta': 'Histórico da meta',
      'No se puede deshacer': 'Esta ação não pode ser desfeita',
      'Registrar gasto': 'Registrar despesa',
      'Agregar producto': 'Adicionar produto',
      'Total estimado': 'Total estimado',
      'La lista está vacía': 'A lista está vazia',
      'Las contraseñas no coinciden': 'As senhas não coincidem',
      'Mínimo 8 caracteres': 'Mínimo de 8 caracteres',
      'Verificando': 'Verificando',
      'Identidad verificada': 'Identidade verificada',
      'Cerrar': 'Fechar',
      'Cancelar': 'Cancelar',
      'Guardar': 'Salvar',
      'Eliminar': 'Excluir',
      'Retirar': 'Retirar',
      'Compartir': 'Compartilhar',
      'No se pudo actualizar el ahorro':
          'Não foi possível atualizar a poupança',
      'Ahorro libre': 'Poupança livre',
      'Ahorra sin tener una meta específica':
          'Economize sem uma meta específica',
      'Ahorro retirado correctamente.': 'Poupança retirada com sucesso.',
      'Ahorro agregado correctamente.': 'Poupança adicionada com sucesso.',
      'Retirar ahorro libre': 'Retirar poupança livre',
      'Agregar ahorro libre': 'Adicionar poupança livre',
      'Cantidad': 'Valor',
      'Cantidad ahorrada': 'Valor economizado',
      'Disponible': 'Disponível',
      'Ahorrado': 'Economizado',
      'A la cuenta': 'Para a conta',
      'En la cuenta': 'Na conta',
      'Selecciona una cuenta.': 'Selecione uma conta.',
      'No hay cuentas activas en la moneda principal.':
          'Não há contas ativas na moeda principal.',
      'Elige cuánto deseas retirar y a qué cuenta devolverlo.':
          'Escolha quanto deseja retirar e para qual conta devolver.',
      'Elige de qué cuenta apartar el dinero, sin asociarlo a una meta.': 'Escolha de qual conta retirar o dinheiro, sem associá-lo a uma meta.',
      'Sin icono': 'Sem ícone',
      'RESUMEN DE AHORRO': 'RESUMO DA POUPANÇA',
      'Disponible en la meta': 'Disponível na meta',
      'Todavía no hay movimientos en esta meta.':
          'Ainda não há movimentações nesta meta.',
      'Ahorro agregado': 'Poupança adicionada',
      'No se pudo crear la meta': 'Não foi possível criar a meta',
      'No se pudo retirar el dinero. Intenta nuevamente.':
          'Não foi possível retirar o dinheiro. Tente novamente.',
      'Nombre de la meta': 'Nome da meta',
      'Ahorro inicial': 'Poupança inicial',
      'Se eliminarán también sus productos.':
          'Os produtos também serão excluídos.',
      'Cuando finalices una lista aparecerá aquí.':
          'Quando você concluir uma lista, ela aparecerá aqui.',
      'Organiza tus productos y controla cuánto vas a gastar.':
          'Organize seus produtos e controle quanto vai gastar.',
      'Tu lista está vacía': 'Sua lista está vazia',
      'Agrega productos para calcular tu compra.':
          'Adicione produtos para calcular sua compra.',
      'Crear lista': 'Criar lista',
      'Nueva lista': 'Nova lista',
      'Renombrar lista': 'Renomear lista',
      'Nombre de la lista': 'Nome da lista',
      'Producto': 'Produto',
      'Editar producto': 'Editar produto',
      'Completa el producto con valores válidos.':
          'Preencha o produto com valores válidos.',
      'Monto inválido': 'Valor inválido',
      'Sin fecha': 'Sem data',
      'El precio se aplicará por:': 'O preço será aplicado por:',
      'Planifica tu próxima compra.': 'Planeje sua próxima compra.',
      'Error de acceso': 'Erro de acesso',
      'Tus datos están protegidos': 'Seus dados estão protegidos',
      'Contraseña actualizada. Ya puedes iniciar sesión.':
          'Senha atualizada. Você já pode entrar.',
      'No existe una cuenta con ese correo':
          'Não existe uma conta com esse e-mail',
      'No se pudo verificar tu identidad':
          'Não foi possível verificar sua identidade',
      'Recupera tu acceso': 'Recupere seu acesso',
      'Descripción': 'Descrição',
      'Fecha': 'Data',
      'El ingreso se agregará a tu saldo.':
          'A receita será adicionada ao seu saldo.',
      'Ingresa un monto válido mayor que cero':
          'Insira um valor válido maior que zero',
      'Escribe una descripción': 'Escreva uma descrição',
      'Ingreso guardado correctamente': 'Receita salva com sucesso',
      'Gasto guardado correctamente': 'Despesa salva com sucesso',
      'Aún no tienes metas. Crea una para empezar a ahorrar con un objetivo.':
          'Você ainda não tem metas. Crie uma para começar a economizar.',
      'Sal de tu cuenta en este dispositivo':
          'Saia da sua conta neste dispositivo',
      'No se pudo cargar el historial': 'Não foi possível carregar o histórico',
      'Esta acción no se puede deshacer.': 'Esta ação não pode ser desfeita.',
      'El ahorro inicial no puede superar la meta':
          'A poupança inicial não pode superar a meta',
      'Dale un propósito a tu ahorro': 'Dê um propósito à sua poupança',
      'Aún no hay gastos registrados en este periodo.':
          'Ainda não há despesas registradas neste período.',
      'Aún no hay ingresos registrados en este periodo.':
          'Ainda não há receitas registradas neste período.',
      'No se pudo cargar el análisis': 'Não foi possível carregar a análise',
      'No se pudo cargar el resumen': 'Não foi possível carregar o resumo',
      'Actualizado el 23 de septiembre de 2026':
          'Atualizado em 23 de setembro de 2026',
      'INFORMACIÓN LEGAL DE MOVA': 'INFORMAÇÕES LEGAIS DA MOVA',
      'CONTENIDO': 'CONTEÚDO',
      'secciones': 'seções',
      'Acepto los ': 'Aceito o ',
      'aviso de privacidad': 'aviso de privacidade',
      'Contraseña débil': 'Senha fraca',
      'Aceptación requerida': 'Aceitação necessária',
      'Revisa tu nombre, correo y contraseña.':
          'Verifique seu nome, e-mail e senha.',
      'Revisa tu correo y contraseña e inténtalo nuevamente.':
          'Verifique seu e-mail e senha e tente novamente.',
      'No fue posible iniciar sesión.': 'Não foi possível entrar.',
      'Escribe tu correo electrónico': 'Digite seu e-mail',
      'Usa mínimo 8 caracteres': 'Use pelo menos 8 caracteres',
      'Administra tu información personal':
          'Gerencie suas informações pessoais',
      'Nombre': 'Nome',
      'Define cuánto quieres gastar': 'Defina quanto quer gastar',
      'Protege tu información': 'Proteja suas informações',
      'Importar datos': 'Importar dados',
      'Importa información existente': 'Importe informações existentes',
      'Consulta cómo se tratan tus datos': 'Veja como seus dados são tratados',
      'Cerrar sesión': 'Sair',
      'Eliminar cuenta': 'Excluir conta',
      'Esta acción es permanente.': 'Esta ação é permanente.',
      'Se eliminarán tu cuenta, movimientos, metas, listas y configuraciones. No podrás recuperar estos datos.': 'Sua conta, movimentações, metas, listas e configurações serão excluídas. Não será possível recuperar esses dados.',
      'No se pudo eliminar la cuenta. Intenta nuevamente.':
          'Não foi possível excluir a conta. Tente novamente.',
      'Más': 'Mais',
      'Importar respaldo': 'Importar backup',
      'El archivo no tiene un formato válido':
          'O formato do arquivo é inválido',
      'Elige qué recordatorios quieres recibir':
          'Escolha quais lembretes deseja receber',
      'Avisos relacionados con tu límite mensual':
          'Avisos relacionados ao seu limite mensal',
      'Versión 1.0.0  ·  Finanzas personales':
          'Versão 1.0.0  ·  Finanças pessoais',
      'Biometría no disponible': 'Biometria indisponível',
      'Verificación no completada': 'Verificação não concluída',
      'Elige una sola forma de proteger tu sesión':
          'Escolha uma forma de proteger sua sessão',
      'Huella o biometría': 'Impressão digital ou biometria',
      'Usa el sensor del dispositivo': 'Use o sensor do dispositivo',
      'Números (PIN)': 'Números (PIN)',
      'Crea un código de 4 a 8 dígitos': 'Crie um código de 4 a 8 dígitos',
      'Desactivar protección': 'Desativar proteção',
      'Crear PIN': 'Criar PIN',
      'PIN de 4 a 8 dígitos': 'PIN de 4 a 8 dígitos',
      'Ingresa un presupuesto válido': 'Insira um orçamento válido',
      'Presupuesto actualizado': 'Orçamento atualizado',
      'Controla tus gastos sin perder de vista tu límite':
          'Controle seus gastos sem perder de vista seu limite',
      'Se reinicia cada lunes y considera tus gastos de esta semana.':
          'Reinicia toda segunda-feira e considera seus gastos desta semana.',
      'Se reinicia el primer día de cada mes.':
          'Reinicia no primeiro dia de cada mês.',
      'Nombre de la categoría': 'Nome da categoria',
      'Icono o emoji': 'Ícone ou emoji',
      'Puedes usar un emoji para identificarla más rápido.':
          'Você pode usar um emoji para identificá-la mais rapidamente.',
      'Pega aquí el JSON exportado desde MOVA. Tus datos actuales no se eliminarán.': 'Cole aqui o JSON exportado do MOVA. Seus dados atuais não serão excluídos.',
      'MOVA está diseñada con un enfoque offline-first. Tus datos principales se mantienen en tu dispositivo.': 'O MOVA foi projetado com uma abordagem offline-first. Seus dados principais ficam no dispositivo.',
      'Organiza ingresos, gastos, metas y compras en un solo espacio, de forma clara y sencilla.': 'Organize receitas, despesas, metas e compras em um só lugar, de forma clara e simples.',
      'Lee estas condiciones para conocer el uso responsable de MOVA.':
          'Leia estas condições para conhecer o uso responsável do MOVA.',
      'Consulta qué información se guarda y cómo puedes administrar tus datos.': 'Veja quais informações são armazenadas e como você pode gerenciar seus dados.',
      'Límite mensual': 'Limite mensal',
      'Quitar límite': 'Remover limite',
      'Moneda de la aplicación': 'Moeda do aplicativo',
      'Esa categoría ya existe para ese tipo':
          'Essa categoria já existe para esse tipo',
      'Aún no tienes categorías personalizadas':
          'Você ainda não tem categorias personalizadas',
      '¿Qué tipo de movimiento será?': 'Que tipo de movimentação será?',
      'Crear categoría': 'Criar categoria',
      'Nueva categoría': 'Nova categoria',
      'Personaliza tus movimientos para encontrarlos fácilmente':
          'Personalize suas movimentações para encontrá-las facilmente',
      'FINANZAS': 'FINANÇAS',
      'APLICACIÓN': 'APLICATIVO',
      'DATOS': 'DADOS',
      'INFORMACIÓN': 'INFORMAÇÕES',
      'CUENTA': 'CONTA',
      'Administra tus categorías de ingresos y gastos':
          'Gerencie suas categorias de receitas e despesas',
      'Organiza productos, calcula y registra tus compras':
          'Organize produtos, calcule e registre suas compras',
      'Gestiona tus recordatorios': 'Gerencie seus lembretes',
      'Consulta las condiciones de uso': 'Veja as condições de uso',
      'Acerca de MOVA': 'Sobre o MOVA',
      'Exportar datos': 'Exportar dados',
      'Descarga tus movimientos': 'Baixe suas movimentações',
      'Todo lo que necesitas para controlar MOVA':
          'Tudo o que você precisa para controlar o MOVA',
      'Crea una meta para darle un objetivo a tus ahorros.':
          'Crie uma meta para dar um objetivo às suas economias.',
      'Al crear una cuenta y utilizar MOVA confirmas que leíste, comprendiste y aceptas estos términos.': 'Ao criar uma conta e usar o MOVA, você confirma que leu, entendeu e aceita estes termos.',
      'MOVA es una herramienta de organización financiera personal para registrar ingresos, gastos, metas, presupuestos y listas.': 'O MOVA é uma ferramenta de organização financeira pessoal para registrar receitas, despesas, metas, orçamentos e listas.',
      'Eres responsable de mantener la confidencialidad de tu correo y contraseña, así como de la actividad realizada desde tu dispositivo.': 'Você é responsável por manter seu e-mail e senha em sigilo, assim como pela atividade realizada no seu dispositivo.',
      'Los cálculos y análisis son orientativos y dependen de los datos que registres. MOVA no sustituye asesoría financiera profesional.': 'Os cálculos e análises são orientativos e dependem dos dados registrados. O MOVA não substitui aconselhamento financeiro profissional.',
      'No debes acceder a cuentas ajenas, alterar la aplicación ni utilizar MOVA para actividades ilegales.': 'Você não deve acessar contas de terceiros, alterar o aplicativo ou usar o MOVA para atividades ilegais.',
      'MOVA puede guardar tu nombre, correo, contraseña, foto de perfil, movimientos, metas, presupuestos, categorías y listas.': 'O MOVA pode armazenar seu nome, e-mail, senha, foto de perfil, movimentações, metas, orçamentos, categorias e listas.',
      'Utilizamos esta información para proteger tu cuenta, mostrar tus finanzas, generar resúmenes y conservar tus preferencias.': 'Usamos essas informações para proteger sua conta, mostrar suas finanças, gerar resumos e manter suas preferências.',
      'La información financiera de MOVA se almacena localmente en el dispositivo para que puedas utilizar la aplicación.': 'As informações financeiras do MOVA são armazenadas localmente no dispositivo para que você possa usar o aplicativo.',
      'Puedes editar o eliminar la información desde las funciones disponibles de MOVA, incluida la eliminación de tu cuenta.': 'Você pode editar ou excluir informações usando os recursos do MOVA, incluindo a exclusão da sua conta.',
      'Tu avance acumulado': 'Seu progresso acumulado',
      'Registra movimientos para obtener recomendaciones.':
          'Registre movimentações para obter recomendações.',
      'Tus gastos superan tus ingresos en':
          'Suas despesas superam suas receitas em',
      'Tu balance positivo es de': 'Seu saldo positivo é de',
      'de': 'de',
      'establecidos': 'definidos',
      'completado': 'concluído',
      'Guardando...': 'Salvando...',
      'Actualizar': 'Atualizar',
      'Quitar foto': 'Remover foto',
      'Agregar foto de perfil': 'Adicionar foto de perfil',
      'Cambiar foto de perfil': 'Alterar foto de perfil',
      'Agrega una foto para personalizar tu cuenta':
          'Adicione uma foto para personalizar sua conta',
      'Tu foto de perfil': 'Sua foto de perfil',
      'Agregar': 'Adicionar',
      'Antes de continuar': 'Antes de continuar',
      'Aporte': 'Contribuição',
      'Borra tu cuenta y todos sus datos':
          'Exclua sua conta e todos os seus dados',
      'Compartir meta': 'Compartilhar meta',
      'Compra incompleta': 'Compra incompleta',
      'Contenido de la copia': 'Conteúdo do backup',
      'Copia lista': 'Cópia pronta',
      'Copiar de nuevo': 'Copiar novamente',
      'Crear QR': 'Criar QR',
      'Crear meta': 'Criar meta',
      'Cuenta existente': 'Conta existente',
      'Define qué necesitas y calcula el costo al instante.':
          'Defina o que precisa e calcule o custo instantaneamente.',
      'Desbloquear': 'Desbloquear',
      'Editar': 'Editar',
      'Editar información de tu cuenta': 'Editar as informações da sua conta',
      'Editar nombre': 'Editar nome',
      'Ej. 8,000.00': 'Ex. 8.000,00',
      'Ej. Comida, transporte o freelance':
          'Ex. Comida, transporte ou freelance',
      'Elige un emoji': 'Escolha um emoji',
      'Eliminar lista': 'Excluir lista',
      'Eliminar meta': 'Excluir meta',
      'Eliminar producto': 'Excluir produto',
      'Escribe tu nombre': 'Digite seu nome',
      'Escribe una cantidad mayor a cero.': 'Digite um valor maior que zero.',
      'Finalizar': 'Concluir',
      'Importar': 'Importar',
      'Licencias': 'Licenças',
      'Límite mensual (': 'Limite mensal (',
      'Mensual': 'Mensal',
      'Moneda general de MOVA': 'Moeda padrão do MOVA',
      'Monto a retirar': 'Valor a retirar',
      'Monto del aporte': 'Valor da contribuição',
      'No se pudo abrir el selector de imágenes:':
          'Não foi possível abrir o seletor de imagens:',
      'No se pudo actualizar el ahorro:':
          'Não foi possível atualizar a poupança:',
      'No se pudo cargar el análisis:': 'Não foi possível carregar a análise:',
      'No se pudo cargar el historial:':
          'Não foi possível carregar o histórico:',
      'No se pudo cargar el resumen:': 'Não foi possível carregar o resumo:',
      'No se pudo completar': 'Não foi possível concluir',
      'No se pudo guardar la preferencia.':
          'Não foi possível salvar a preferência.',
      'El correo electrónico ya está registrado.':
          'Este e-mail já está registrado.',
      'No se pudo guardar el movimiento:':
          'Não foi possível salvar a movimentação:',
      'La biometría no está disponible o no está configurada en este dispositivo.': 'A biometria não está disponível ou não está configurada neste dispositivo.',
      'La verificación fue cancelada.': 'A verificação foi cancelada.',
      'No se pudo verificar tu identidad. Confirma que tienes una huella o rostro registrado en los ajustes del teléfono.': 'Não foi possível verificar sua identidade. Confirme se há uma impressão digital ou rosto cadastrado nas configurações do telefone.',
      'El sistema biométrico devolvió un error. Verifica la biometría configurada en tu teléfono e inténtalo nuevamente.': 'O sistema biométrico retornou um erro. Verifique a biometria configurada no telefone e tente novamente.',
      'Presupuesto excedido': 'Orçamento excedido',
      'Precio pendiente': 'Preço pendente',
      'Precio opcional': 'Preço opcional',
      'Opcional · JPG, PNG o WebP': 'Opcional · JPG, PNG ou WebP',
      'PROGRESO DE LA META': 'PROGRESSO DA META',
      'Permite recibir recordatorios de Mova':
          'Permitir receber lembretes do Mova',
      'Por ': 'Por ',
      'Presupuesto ': 'Orçamento ',
      'QR de aporte': 'QR de contribuição',
      'Recordatorios para avanzar en tus metas':
          'Lembretes para avançar nas suas metas',
      'Registrar compra': 'Registrar compra',
      'Respaldo local': 'Backup local',
      'Tu información está preparada para guardarse':
          'Suas informações estão prontas para serem salvas',
      'Agrega información de otra copia de MOVA':
          'Adicione informações de outro backup do MOVA',
      'Solo se importan movimientos válidos. La información existente se conserva.': 'Somente movimentações válidas são importadas. As informações existentes são preservadas.',
      'Cambiar la moneda no modifica el límite configurado.':
          'Alterar a moeda não modifica o limite configurado.',
      'El archivo se copió al portapapeles. Pégalo en un lugar seguro para conservarlo.': 'O arquivo foi copiado para a área de transferência. Cole-o em um local seguro para guardá-lo.',
      'movimientos': 'movimentações',
      'metas': 'metas',
      'listas': 'listas',
      'Se aplicará a ingresos, gastos, metas, compras y presupuesto. No convierte cantidades existentes.': 'Aplica-se a receitas, despesas, metas, compras e orçamentos. Não converte valores existentes.',
      'Tu límite semanal quedó en': 'Seu limite semanal ficou em',
      'Tu límite mensual quedó en': 'Seu limite mensal ficou em',
      'Revisa el producto': 'Revise o produto',
      'Semanal': 'Semanal',
      'Total': 'Total',
      'Tu balance positivo es de ': 'Seu saldo positivo é de ',
      'Tu dinero, en movimiento.': 'Seu dinheiro em movimento.',
      'Usa un nombre fácil de reconocer.': 'Use um nome fácil de reconhecer.',
      'Versión 1.0.0': 'Versão 1.0.0',
      '¿De dónde provino este ingreso?': 'De onde veio esta receita?',
      '¿Ya tienes una cuenta?': 'Já tem uma conta?',
      'Activar notificaciones': 'Ativar notificações',
      'Agrega al menos un producto antes de finalizar.':
          'Adicione pelo menos um produto antes de concluir.',
      'movimientos importados': 'movimentações importadas',
      'y el ': 'e o ',
      'Verificando...': 'Verificando...',
      'Verificar con huella': 'Verificar com impressão digital',
      'Escribe una cantidad mayor a cero': 'Digite um valor maior que zero.',
      'Ingresa un monto mayor que cero': 'Digite um valor maior que zero',
      'Ingresa un correo electrónico válido.': 'Digite um e-mail válido.',
      'Usa al menos 8 caracteres, una mayúscula, un número o un símbolo.': 'Use pelo menos 8 caracteres, uma letra maiúscula, número ou símbolo.',
      'Las contraseñas no coinciden.': 'As senhas não coincidem.',
      'Debes aceptar los términos y condiciones.':
          'Você deve aceitar os termos e condições.',
      'Términos y condiciones': 'Termos e condições',
      'Aviso de privacidad': 'Aviso de privacidade',
      'meta activa': 'meta ativa',
      'metas activas': 'metas ativas',
      'Retiro': 'Retirada',
      'Compra finalizada': 'Compra concluída',
      'Control de compra': 'Controle da compra',
      'Agregado al carrito': 'Adicionado ao carrinho',
      'Pendiente por comprar': 'Pendente para comprar',
      'gastado hasta hoy': 'gasto até hoje',
      'Sueldo': 'Salário',
      'Freelance': 'Freelance',
      'Inversión': 'Investimento',
      'Regalo': 'Presente',
      'Venta': 'Venda',
      'Otro': 'Outro',
      'Comida': 'Comida',
      'Transporte': 'Transporte',
      'Compras': 'Compras',
      'Hogar': 'Casa',
      'Entretenimiento': 'Entretenimento',
      'Ahorro': 'Poupança',
      'Ahorro sin meta': 'Poupança sem meta',
      'Otros': 'Outros',
      'Aparta una cantidad sin asociarla a una meta.':
          'Separe um valor sem associá-lo a uma meta.',
      'Lista en curso': 'Lista em andamento',
      'No se pudieron cargar los movimientos:':
          'Não foi possível carregar as movimentações:',
      'Nueva contraseña': 'Nova senha',
      'Confirmar contraseña': 'Confirmar senha',
    },
  };

  static MovaLocalizations of(BuildContext context) =>
      Localizations.of<MovaLocalizations>(context, MovaLocalizations)!;
}

class _MovaLocalizationsDelegate
    extends LocalizationsDelegate<MovaLocalizations> {
  const _MovaLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en', 'pt'].contains(locale.languageCode);

  @override
  Future<MovaLocalizations> load(Locale locale) async =>
      MovaLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<MovaLocalizations> old) =>
      false;
}

extension MovaLocalizationBuildContext on BuildContext {
  MovaLocalizations get l10n => MovaLocalizations.of(this);
}

String movaText(String source) =>
    MovaLocalizations(appLanguageController.language.locale).translate(source);
