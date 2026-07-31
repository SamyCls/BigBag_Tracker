import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

/// Gère la langue de l'application (fr / ar), persistée localement.
class LanguageProvider extends ChangeNotifier {
  static const _key = 'dr_language_code';

  String _languageCode = 'fr';
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_key) ?? 'fr';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode != 'fr' && langCode != 'ar') return;
    _languageCode = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
  }
}

/// Helper pour obtenir les traductions de l'application.
class L {
  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      // Nav
      'nav_production': "Production",
      'nav_stock': "Stock",
      'nav_chargement': "Chargement",
      'nav_historique': "Historique",
      'nav_reglages': "Réglages",

      // Production
      'prod_title': "Production Big Bag",
      'prod_new': "NOUVEAU BIG BAG",
      'prod_recent': "Derniers produits",
      'prod_poids': "Poids brut",
      'prod_qualite': "Qualité",
      'prod_kg': "kg",
      'prod_valider': "VALIDER",
      'prod_annuler': "Annuler",
      'prod_ecrire_sac': "Écrire ce numéro sur le sac",
      'prod_created': "Big Bag créé",
      'prod_suggestions': "Suggestions",
      'prod_subtitle': "Tapez pour créer un nouveau Big Bag · pesée manuelle",
      'prod_changer_date': "Changer la date",
      'prod_changer': "Changer",
      'prod_sacs': "sac(s)",
      'prod_today': "Produits d'aujourd'hui",
      'prod_from': "Produits du",
      'prod_empty_today': "Aucun Big Bag produit aujourd'hui",
      'prod_empty_day': "Aucun Big Bag produit ce jour-là",
      'prod_past_day_locked': "Création désactivée · vous ne pouvez créer que pour aujourd'hui",
      'prod_id_auto': "ID GÉNÉRÉ AUTOMATIQUEMENT",
      'prod_id_prevu': "ID prévu",
      'prod_created_toast': "créé · écrire ce numéro sur le sac",
      'prod_intro_subtitle': "Pesée · qualité · validation en 3 taps",
      'prod_edit_dialog_title': "Choisir une action",
      'prod_edit_dialog_modify': "Modifier le poids",
      'prod_edit_dialog_delete': "Supprimer le sac",
      'prod_confirm_delete_title': "Confirmer la suppression",
      'prod_confirm_delete_body': "Êtes-vous sûr de vouloir supprimer ce Big Bag ?",
      'prod_modify_dialog_title': "Modifier le poids",
      'prod_confirm_save_title': "Confirmer l'enregistrement",
      'prod_confirm_save_body': "Êtes-vous sûr d'enregistrer le nouveau poids ?",
      'prod_save': "Enregistrer",

      // Stock
      'stock_title': "Stock Big Bags",
      'stock_filter_all': "Tous",
      'stock_filter_stock': "En stock",
      'stock_filter_charge': "Chargés",
      'stock_filter_expedie': "Expédiés",
      'stock_total_bb': "Big Bags",
      'stock_poids_total': "Poids total",
      'stock_empty': "Aucun Big Bag",
      'stock_search': "Chercher BB-…",
      'stock_subtitle': "Vue temps réel — synchronisée localement",
      'stock_all_dates': "Toutes les dates",
      'stock_today': "Aujourd'hui",

      // Statuts
      'st_stock': "EN STOCK",
      'st_charge': "CHARGÉ",
      'st_expedie': "EXPÉDIÉ",

      // Chargement
      'ch_title': "Chargements",
      'ch_new': "NOUVEAU CHARGEMENT",
      'ch_active': "Chargements en cours",
      'ch_setup': "Nouveau chargement",
      'ch_client': "Client",
      'ch_camion': "Camion (optionnel)",
      'ch_chauffeur': "Chauffeur (optionnel)",
      'ch_client_ph': "Nom du client",
      'ch_camion_ph': "Immatriculation",
      'ch_chauffeur_ph': "Nom du chauffeur",
      'ch_start': "DÉMARRER",
      'ch_session': "Session de chargement",
      'ch_add_bb': "Ajouter Big Bag",
      'ch_scan_ph': "BB-______",
      'ch_add': "AJOUTER",
      'ch_pause': "PAUSE",
      'ch_terminer': "TERMINER",
      'ch_nb_bb': "Nb Big Bags",
      'ch_brut': "Poids brut",
      'ch_custom_weight': "Poids",
      'ch_tare': "Tare (3 kg × BB)",
      'ch_net': "Poids NET",
      'ch_liste': "Big Bags chargés",
      'ch_deja_charge': "Déjà chargé dans un autre camion",
      'ch_deja_expedie': "Ce Big Bag est déjà expédié",
      'ch_introuvable': "Big Bag introuvable",
      'ch_ajoute': "Ajouté",
      'ch_retirer': "Retirer",
      'ch_reprendre': "Reprendre",
      'ch_paused': "En pause",
      'ch_subtitle': "Saisissez client, camion et chauffeur pour démarrer",
      'ch_empty_active': "Aucun chargement en cours",
      'ch_empty_stock': "AUCUN SAC EN STOCK",
      'ch_all_added': "Tous les sacs ont été ajoutés",
      'ch_recent_top': "Plus récent en haut",
      'ch_empty_session': "Ajoutez votre premier Big Bag",
      'ch_cancel_confirm_title': "Annuler le chargement ?",
      'ch_cancel_confirm_body':
          "Tous les Big Bags seront remis en stock et ce chargement sera supprimé définitivement.",
      'ch_confirm_cancel': "Oui, annuler",

      // Bon
      'bon_title': "Bon d'expédition",
      'bon_num': "N°",
      'bon_date': "Date",
      'bon_client': "Client",
      'bon_camion': "Camion",
      'bon_chauffeur': "Chauffeur",
      'bon_nb': "Nombre de Big Bags",
      'bon_brut': "Poids brut total",
      'bon_tare': "Tare totale",
      'bon_net': "Poids net",
      'bon_liste': "Liste des Big Bags",
      'bon_imprimer': "IMPRIMER / PDF",
      'bon_fermer': "Fermer",
      'bon_signature': "Signature transporteur",
      'bon_delta': "Delta Recycl — Recyclage PET",
      'bon_footer': "Bon généré automatiquement — Delta Recycl",
      'bon_share': "PARTAGER",
      'bon_tare_desc': "Tare totale (3 x ",
      'bon_signature_delta': "Signature Delta Recycl",

      // Historique
      'hist_title': "Historique des expéditions",
      'hist_empty': "Aucun chargement",
      'hist_reimprimer': "Rouvrir le bon",
      'hist_subtitle': "bon(s)",
      'hist_search': "Chercher bon (ex: 42)",
      'hist_all_dates': "Toutes les dates",
      'hist_this_week': "Cette semaine",
      'hist_this_month': "Ce mois",
      'hist_all': "Tout",
      'hist_no_results': "Aucun résultat",

      // Réglages
      'set_title': "Réglages",
      'set_langue': "Langue",
      'set_theme': "Thème",
      'set_light': "Clair",
      'set_dark': "Sombre",
      'set_data': "Données",
      'set_reset': "Réinitialiser les données",
      'set_reset_confirm': "Effacer toutes les données ?",
      'set_export': "Exporter",
      'set_version': "Version démo — Delta Recycl",
      'set_subtitle': "Préférences locales de cette tablette",
      'set_reset_confirm_body':
          "Cette action est irréversible : tous les Big Bags et chargements seront supprimés.",
      'set_password': "Mot de passe",
      'set_wrong_password': "Mot de passe incorrect",
      'set_reset_sequence':
          "Réinitialiser aussi la numérotation (repartir de BB-000001)",
      'set_langue_section': "LANGUE",

      // Common
      'ok': "OK",
      'cancel': "Annuler",
      'yes': "Oui",
      'no': "Non",
      'close': "Fermer",
      'back': "Retour",
      'confirm': "Confirmer",
      'saved': "Enregistré",
      'kg': "kg",
      'quality_clear': "Bleu clair",
      'quality_mixte': "Mixte",
      'quality_colore': "Coloré",
    },
    'ar': {
      // Nav
      'nav_production': "الإنتاج",
      'nav_stock': "المخزون",
      'nav_chargement': "التحميل",
      'nav_historique': "السجل",
      'nav_reglages': "الإعدادات",

      // Production
      'prod_title': "إنتاج الأكياس الكبيرة",
      'prod_new': "كيس كبير جديد",
      'prod_recent': "أحدث المنتجات",
      'prod_poids': "الوزن الإجمالي",
      'prod_qualite': "الجودة",
      'prod_kg': "كغ",
      'prod_valider': "تأكيد",
      'prod_annuler': "إلغاء",
      'prod_ecrire_sac': "اكتب هذا الرقم على الكيس",
      'prod_created': "تم إنشاء الكيس",
      'prod_suggestions': "اقتراحات",
      'prod_subtitle': "انقر لإنشاء كيس كبير جديد · وزن يدوي",
      'prod_changer_date': "تغيير التاريخ",
      'prod_changer': "تغيير",
      'prod_sacs': "أكياس",
      'prod_today': "منتجات اليوم",
      'prod_from': "منتجات يوم",
      'prod_empty_today': "لم يتم إنتاج أي كيس كبير اليوم",
      'prod_empty_day': "لم يتم إنتاج أي كيس كبير في هذا اليوم",
      'prod_past_day_locked': "الإنشاء معطّل · يمكنك الإنشاء فقط لليوم الحالي",
      'prod_id_auto': "المعرف مُنشأ تلقائياً",
      'prod_id_prevu': "المعرف المتوقع",
      'prod_created_toast': "تم إنشاؤه · اكتب هذا الرقم على الكيس",
      'prod_intro_subtitle': "الوزن · الجودة · التأكيد في 3 نقرات",
      'prod_edit_dialog_title': "اختر إجراءً",
      'prod_edit_dialog_modify': "تعديل الوزن",
      'prod_edit_dialog_delete': "حذف الكيس",
      'prod_confirm_delete_title': "تأكيد الحذف",
      'prod_confirm_delete_body': "هل أنت متأكد من حذف هذا الكيس؟",
      'prod_modify_dialog_title': "تعديل الوزن",
      'prod_confirm_save_title': "تأكيد الحفظ",
      'prod_confirm_save_body': "هل أنت متأكد من حفظ الوزن الجديد؟",
      'prod_save': "حفظ",

      // Stock
      'stock_title': "مخزون الأكياس",
      'stock_filter_all': "الكل",
      'stock_filter_stock': "في المخزون",
      'stock_filter_charge': "محمّل",
      'stock_filter_expedie': "مُرسل",
      'stock_total_bb': "أكياس",
      'stock_poids_total': "الوزن الإجمالي",
      'stock_empty': "لا توجد أكياس",
      'stock_search': "ابحث BB-…",
      'stock_subtitle': "عرض مباشر — متزامن محلياً",
      'stock_all_dates': "كل التواريخ",
      'stock_today': "اليوم",

      // Statuts
      'st_stock': "في المخزون",
      'st_charge': "محمّل",
      'st_expedie': "مُرسل",

      // Chargement
      'ch_title': "التحميلات",
      'ch_new': "تحميل جديد",
      'ch_active': "تحميلات جارية",
      'ch_setup': "تحميل جديد",
      'ch_client': "الزبون",
      'ch_camion': "الشاحنة (اختياري)",
      'ch_chauffeur': "السائق (اختياري)",
      'ch_client_ph': "اسم الزبون",
      'ch_camion_ph': "رقم التسجيل",
      'ch_chauffeur_ph': "اسم السائق",
      'ch_start': "بدء",
      'ch_session': "جلسة التحميل",
      'ch_add_bb': "إضافة كيس",
      'ch_scan_ph': "BB-______",
      'ch_add': "إضافة",
      'ch_pause': "إيقاف",
      'ch_terminer': "إنهاء التحميل",
      'ch_nb_bb': "عدد الأكياس",
      'ch_brut': "الوزن الإجمالي",
      'ch_custom_weight': "الوزن",
      'ch_tare': "الوزن الفارغ (3 كغ × كيس)",
      'ch_net': "الوزن الصافي",
      'ch_liste': "الأكياس المحملة",
      'ch_deja_charge': "محمّل في شاحنة أخرى",
      'ch_deja_expedie': "هذا الكيس تم إرساله",
      'ch_introuvable': "الكيس غير موجود",
      'ch_ajoute': "تمت الإضافة",
      'ch_retirer': "إزالة",
      'ch_reprendre': "بدء مجددا",
      'ch_paused': "متوقف",
      'ch_subtitle': "أدخل معلومات الزبون، الشاحنة والسائق للبدء",
      'ch_empty_active': "لا توجد عمليات تحميل جارية",
      'ch_empty_stock': "لا توجد أكياس في المخزون",
      'ch_all_added': "تمت إضافة جميع الأكياس",
      'ch_recent_top': "الأحدث في الأعلى",
      'ch_empty_session': "أضف أول كيس كبير لك",
      'ch_cancel_confirm_title': "إلغاء التحميل؟",
      'ch_cancel_confirm_body':
          "ستتم إعادة جميع الأكياس الكبيرة إلى المخزون وسيتم حذف عملية التحميل هذه نهائياً.",
      'ch_confirm_cancel': "نعم، إلغاء",

      // Bon
      'bon_title': "سند الإرسال",
      'bon_num': "رقم",
      'bon_date': "التاريخ",
      'bon_client': "الزبون",
      'bon_camion': "الشاحنة",
      'bon_chauffeur': "السائق",
      'bon_nb': "عدد الأكياس",
      'bon_brut': "الوزن الإجمالي",
      'bon_tare': "الوزن الفارغ",
      'bon_net': "الوزن الصافي",
      'bon_liste': "قائمة الأكياس",
      'bon_imprimer': "طباعة / PDF",
      'bon_fermer': "إغلاق",
      'bon_signature': "توقيع الناقل",
      'bon_delta': "دلتا ريسيكل — تدوير PET",
      'bon_footer': "سند مُنشأ تلقائياً — دلتا ريسيكل",
      'bon_share': "مشاركة",
      'bon_tare_desc': "الوزن الفارغ الإجمالي (3 × ",
      'bon_signature_delta': "توقيع دلتا ريسيكل",

      // Historique
      'hist_title': "سجل التحميلات",
      'hist_empty': "لا توجد تحميلات",
      'hist_reimprimer': "إعادة فتح السند",
      'hist_subtitle': "سندات",
      'hist_search': "البحث عن سند (مثال: 42)",
      'hist_all_dates': "كل التواريخ",
      'hist_this_week': "هذا الأسبوع",
      'hist_this_month': "هذا الشهر",
      'hist_all': "الكل",
      'hist_no_results': "لا توجد نتائج",

      // Réglages
      'set_title': "الإعدادات",
      'set_langue': "اللغة",
      'set_theme': "المظهر",
      'set_light': "فاتح",
      'set_dark': "داكن",
      'set_data': "البيانات",
      'set_reset': "إعادة تعيين البيانات",
      'set_reset_confirm': "حذف كل البيانات؟",
      'set_export': "تصدير",
      'set_version': "نسخة تجريبية — دلتا ريسيكل",
      'set_subtitle': "التفضيلات المحلية لهذا الجهاز",
      'set_reset_confirm_body':
          "هذا الإجراء غير قابل للتراجع: سيتم حذف جميع الأكياس والشحنات.",
      'set_password': "كلمة المرور",
      'set_wrong_password': "كلمة مرور خاطئة",
      'set_reset_sequence': "إعادة تعيين الترقيم أيضاً (البدء من BB-000001)",
      'set_langue_section': "اللغة",

      // Common
      'ok': "موافق",
      'cancel': "إلغاء",
      'yes': "نعم",
      'no': "لا",
      'close': "إغلاق",
      'back': "رجوع",
      'confirm': "تأكيد",
      'saved': "تم الحفظ",
      'kg': "كغ",
      'quality_clear': "أزرق فاتح",
      'quality_mixte': "مختلط",
      'quality_colore': "ملوّن",
    },
  };
}

/// Raccourci pour utiliser la traduction via BuildContext
extension TranslationExtension on BuildContext {
  String tr(String key) {
    final code = read<LanguageProvider>().languageCode;
    return L._localizedValues[code]?[key] ?? key;
  }
}
