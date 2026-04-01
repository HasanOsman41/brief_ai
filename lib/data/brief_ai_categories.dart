/// BriefAI – Category Registry  (single source of truth)
///
/// HOW TO ADD A NEW CATEGORY
/// ─────────────────────────
/// All labels and next-step strings live in l10n/app_*.arb.
/// Use 'cat_<id>_label' for the name and 'cat_<id>_step1..N' for steps.
/// 1. If it needs a new main group → add a value to [MainCategory] in
///    document_result.dart, then add a [MainCategoryDefinition] to [mainGroups].
/// 2. Add a [CategoryDefinition] to [all], setting [mainCategory] to the
///    correct group. That's it – the analyzer picks it up automatically.
///
/// Jobcenter section: jobcenter_modelle.docx (21 sub-categories)

// ignore_for_file: prefer_single_quotes

import '../models/category_definition.dart';
import '../models/document_result.dart';

class BriefAiCategories {
  BriefAiCategories._();

  // // ───────────────────────────────────────────────────────────────────────────
  // // MAIN GROUPS
  // // Labels for the 10 top-level buckets shown in the app UI.
  // // Sub-categories reference these via their [mainCategory] field.
  // // ───────────────────────────────────────────────────────────────────────────
  // static const List<MainCategoryDefinition> mainGroups = [
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryJobcenter,
  //     labelKey: 'cat_categoryJobcenter_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryAuslaenderbehoerde,
  //     labelKey: 'cat_categoryAuslaenderbehoerde_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryKrankenkasse,
  //     labelKey: 'cat_categoryKrankenkasse_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryFinanzamt,
  //     labelKey: 'cat_categoryFinanzamt_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryBank,
  //     labelKey: 'cat_categoryBank_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryInsurance,
  //     labelKey: 'cat_categoryInsurance_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryRent,
  //     labelKey: 'cat_categoryRent_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryBills,
  //     labelKey: 'cat_categoryBills_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryContracts,
  //     labelKey: 'cat_categoryContracts_label',
  //   ),
  //   MainCategoryDefinition(
  //     value: MainCategory.categoryOther,
  //     labelKey: 'cat_categoryOther_label',
  //   ),
  // ];

  // GET STEPS BY ID
  static List<String> getStepsById(String id) {
    try {
      return all.firstWhere((c) => c.id == id).nextStepKeys;
    } catch (_) {
      return [];
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUB-CATEGORIES
  // Every entry declares its own [mainCategory] so the full picture of any
  // category is visible in one place. The analyzer reads only this list.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<CategoryDefinition> all = [
    // ─────────────────────────────────────────────────────────────────────
    // JOBCENTER  (21 categories)
    // ─────────────────────────────────────────────────────────────────────

    // 1) Mitwirkung
    CategoryDefinition(
      id: 'jobcenter_mitwirkung',
      labelKey: 'cat_jobcenter_mitwirkung_label',
      summaryKey: 'cat_jobcenter_mitwirkung_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Aufforderung zur Mitwirkung',
        'Mitwirkungspflicht',
        'fehlende Unterlagen',
        'Nachweise fehlen',
      ],
      decisiveKeywords: [
        'bitte reichen Sie folgende Unterlagen ein',
        'wir benötigen noch folgende Unterlagen',
        'folgende Unterlagen werden noch benötigt',
        'zur weiteren Bearbeitung benötigen wir folgende Unterlagen',
        'fehlende Unterlagen sind nachzureichen',
        'bitte legen Sie die folgenden Nachweise vor',
      ],
      supportingKeywords: [
        'Nachweise',
        'Unterlagen',
        'Kontoauszüge',
        'Einkommensnachweis',
        'Lohnabrechnung',
        'Mietvertrag',
        'Mietbescheinigung',
        'Bescheinigung',
      ],
      weakNegativeKeywords: [
        'Einladung zum Termin',
        'persönliches Erscheinen',
        'Termin mit Uhrzeit',
        'Bitte erscheinen Sie',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Ablehnungsbescheid',
        'Änderungsbescheid',
        'Aufhebungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_mitwirkung_step1',
        'cat_jobcenter_mitwirkung_step2',
        'cat_jobcenter_mitwirkung_step3',
        'cat_jobcenter_mitwirkung_step4',
        'cat_jobcenter_mitwirkung_step5',
        'cat_jobcenter_mitwirkung_step6',
      ],
      riskLevel: RiskLevel.high,
    ),

    // 2) Einkommensbescheinigung
    CategoryDefinition(
      id: 'jobcenter_einkommensbescheinigung',
      labelKey: 'cat_jobcenter_einkommensbescheinigung_label',
      summaryKey: 'cat_jobcenter_einkommensbescheinigung_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Einkommensbescheinigung',
        'vom Arbeitgeber auszufüllen',
        'Bescheinigung des Arbeitgebers',
        'Angaben zum Einkommen',
      ],
      decisiveKeywords: [
        'vom Arbeitgeber auszufüllen',
        'Bescheinigung des Arbeitgebers',
        'Angaben zum Arbeitsentgelt',
        'Bruttoarbeitsentgelt',
        'Nettoarbeitsentgelt',
        'Beschäftigung besteht seit',
      ],
      supportingKeywords: [
        'Arbeitgeber',
        'Arbeitsentgelt',
        'Brutto',
        'Netto',
        'Lohn',
        'Gehalt',
        'Beschäftigungsverhältnis',
        'Unterschrift des Arbeitgebers',
      ],
      weakNegativeKeywords: [
        'Arbeitsbescheinigung',
        'Anlage EK',
        'Veränderungsmitteilung',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Ablehnungsbescheid',
        'Änderungsbescheid',
        'Einladung',
      ],
      nextStepKeys: [
        'cat_jobcenter_einkommensbescheinigung_step1',
        'cat_jobcenter_einkommensbescheinigung_step2',
        'cat_jobcenter_einkommensbescheinigung_step3',
        'cat_jobcenter_einkommensbescheinigung_step4',
        'cat_jobcenter_einkommensbescheinigung_step5',
        'cat_jobcenter_einkommensbescheinigung_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 3) Arbeitsbescheinigung
    CategoryDefinition(
      id: 'jobcenter_arbeitsbescheinigung',
      labelKey: 'cat_jobcenter_arbeitsbescheinigung_label',
      summaryKey: 'cat_jobcenter_arbeitsbescheinigung_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Arbeitsbescheinigung',
        'vom Arbeitgeber auszufüllen',
        'Angaben zum Beschäftigungsverhältnis',
        'Beendigung des Beschäftigungsverhältnisses',
      ],
      decisiveKeywords: [
        'Arbeitsbescheinigung',
        'Ende des Beschäftigungsverhältnisses',
        'Grund der Beendigung',
        'letzter Arbeitstag',
        'Kündigung durch Arbeitgeber',
        'Kündigung durch Arbeitnehmer',
      ],
      supportingKeywords: [
        'Arbeitgeber',
        'Eintrittsdatum',
        'Austrittsdatum',
        'Kündigung',
        'befristet',
        'unbefristet',
        'Arbeitszeit',
        'Arbeitslohn',
      ],
      weakNegativeKeywords: [
        'Einkommensbescheinigung',
        'Anlage EK',
        'Einladung',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Ablehnungsbescheid',
        'Änderungsbescheid',
        'Weiterbewilligungsantrag',
      ],
      nextStepKeys: [
        'cat_jobcenter_arbeitsbescheinigung_step1',
        'cat_jobcenter_arbeitsbescheinigung_step2',
        'cat_jobcenter_arbeitsbescheinigung_step3',
        'cat_jobcenter_arbeitsbescheinigung_step4',
        'cat_jobcenter_arbeitsbescheinigung_step5',
        'cat_jobcenter_arbeitsbescheinigung_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 4) Einladung
    CategoryDefinition(
      id: 'jobcenter_einladung',
      labelKey: 'cat_jobcenter_einladung_label',
      summaryKey: 'cat_jobcenter_einladung_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Einladung',
        'Meldeaufforderung',
        'Ihr Termin',
        'persönliche Vorsprache',
      ],
      decisiveKeywords: [
        'bitte erscheinen Sie am',
        'Sie sind eingeladen',
        'Termin am',
        'persönliches Erscheinen erforderlich',
        'Meldezweck',
        'Uhrzeit',
      ],
      supportingKeywords: [
        'Vorsprache',
        'Gespräch',
        'Raum',
        'Uhrzeit',
        'Termin',
        'wahrnehmen',
        'erscheinen',
        'Standort',
      ],
      weakNegativeKeywords: [
        'Mitwirkung',
        'Unterlagen einreichen',
        'WBA',
        'Veränderungsmitteilung',
      ],
      strongNegativeKeywords: [
        'Hauptantrag',
        'Anlage EK',
        'Bewilligungsbescheid',
        'Arbeitsbescheinigung',
      ],
      nextStepKeys: [
        'cat_jobcenter_einladung_step1',
        'cat_jobcenter_einladung_step2',
        'cat_jobcenter_einladung_step3',
        'cat_jobcenter_einladung_step4',
        'cat_jobcenter_einladung_step5',
        'cat_jobcenter_einladung_step6',
      ],
      riskLevel: RiskLevel.high,
    ),

    // 5) WBA – Weiterbewilligungsantrag
    CategoryDefinition(
      id: 'jobcenter_wba',
      labelKey: 'cat_jobcenter_wba_label',
      summaryKey: 'cat_jobcenter_wba_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Antrag auf Weiterbewilligung',
        'Weiterbewilligungsantrag',
        'Leistungen weiterbewilligen',
        'Bürgergeld WBA',
      ],
      decisiveKeywords: [
        'Antrag auf Weiterbewilligung der Leistungen',
        'Weiterbewilligungsantrag',
        'Bewilligungszeitraum endet',
        'damit die Leistungen weitergezahlt werden können',
        'Antrag rechtzeitig stellen',
        'Weiterbewilligung beantragen',
      ],
      supportingKeywords: [
        'Weiterbewilligung',
        'Bewilligungszeitraum',
        'Leistungen',
        'Antrag',
        'Fortzahlung',
        'Bürgergeld',
        'Antragsteller',
        'Weiterzahlung',
      ],
      weakNegativeKeywords: [
        'Hauptantrag',
        'Veränderungsmitteilung',
        'Anlage EK',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Änderungsbescheid',
        'Aufhebungsbescheid',
        'Einladung',
      ],
      nextStepKeys: [
        'cat_jobcenter_wba_step1',
        'cat_jobcenter_wba_step2',
        'cat_jobcenter_wba_step3',
        'cat_jobcenter_wba_step4',
        'cat_jobcenter_wba_step5',
        'cat_jobcenter_wba_step6',
      ],
      riskLevel: RiskLevel.high,
    ),

    // 6) VÄM – Veränderungsmitteilung
    CategoryDefinition(
      id: 'jobcenter_vaem',
      labelKey: 'cat_jobcenter_vaem_label',
      summaryKey: 'cat_jobcenter_vaem_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Veränderungsmitteilung',
        'Änderungen in Ihren Verhältnissen',
        'Mitteilung über Änderungen',
        'Angaben zur Änderung',
      ],
      decisiveKeywords: [
        'ich teile folgende Änderung mit',
        'Änderung der persönlichen Verhältnisse',
        'Änderung des Einkommens',
        'Änderung der Miete',
        'Änderung der Bankverbindung',
        'Änderung der Haushaltsverhältnisse',
      ],
      supportingKeywords: [
        'Änderung',
        'neue Anschrift',
        'neues Einkommen',
        'Einzug',
        'Auszug',
        'Miete',
        'Arbeitgeber',
        'Konto',
      ],
      weakNegativeKeywords: [
        'Hauptantrag',
        'WBA',
        'Anlage EK',
        'Einladung',
      ],
      strongNegativeKeywords: [
        'Änderungsbescheid',
        'Bewilligungsbescheid',
        'Aufhebungsbescheid',
        'Aufforderung zur Mitwirkung',
      ],
      nextStepKeys: [
        'cat_jobcenter_vaem_step1',
        'cat_jobcenter_vaem_step2',
        'cat_jobcenter_vaem_step3',
        'cat_jobcenter_vaem_step4',
        'cat_jobcenter_vaem_step5',
        'cat_jobcenter_vaem_step6',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // 7) HA – Hauptantrag
    CategoryDefinition(
      id: 'jobcenter_hauptantrag',
      labelKey: 'cat_jobcenter_hauptantrag_label',
      summaryKey: 'cat_jobcenter_hauptantrag_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Hauptantrag',
        'Antrag auf Bürgergeld',
        'Leistungen nach dem SGB II',
        'Hauptantrag Bürgergeld',
      ],
      decisiveKeywords: [
        'Antrag auf Bürgergeld',
        'Hauptantrag',
        'Angaben zur antragstellenden Person',
        'ich beantrage Leistungen',
        'Bedarfsgemeinschaft',
        'persönliche Verhältnisse',
      ],
      supportingKeywords: [
        'Antragsteller',
        'Unterkunft',
        'Einkommen',
        'Vermögen',
        'Bankverbindung',
        'Bedarfsgemeinschaft',
        'Unterschrift',
        'Leistungen',
      ],
      weakNegativeKeywords: [
        'Weiterbewilligungsantrag',
        'Veränderungsmitteilung',
        'Anlage EK',
        'Anlage KDU',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Aufforderung zur Mitwirkung',
        'Ablehnungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_hauptantrag_step1',
        'cat_jobcenter_hauptantrag_step2',
        'cat_jobcenter_hauptantrag_step3',
        'cat_jobcenter_hauptantrag_step4',
        'cat_jobcenter_hauptantrag_step5',
        'cat_jobcenter_hauptantrag_step6',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // 8) Anlage EK
    CategoryDefinition(
      id: 'jobcenter_anlage_ek',
      labelKey: 'cat_jobcenter_anlage_ek_label',
      summaryKey: 'cat_jobcenter_anlage_ek_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage EK',
        'Angaben zum Einkommen',
        'Einkommen der Person',
        'Anlage Einkommen',
      ],
      decisiveKeywords: [
        'Anlage EK',
        'Angaben zum Einkommen',
        'Einkommen aus nichtselbständiger Arbeit',
        'sonstiges Einkommen',
        'monatliches Einkommen',
        'Einnahmen',
      ],
      supportingKeywords: [
        'Lohn',
        'Gehalt',
        'Rente',
        'Unterhalt',
        'Einnahmen',
        'Einkommen',
        'brutto',
        'netto',
      ],
      weakNegativeKeywords: [
        'Einkommensbescheinigung',
        'Anlage EKS',
        'Arbeitsbescheinigung',
        'Veränderungsmitteilung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Hauptantrag',
        'Aufforderung zur Mitwirkung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_ek_step1',
        'cat_jobcenter_anlage_ek_step2',
        'cat_jobcenter_anlage_ek_step3',
        'cat_jobcenter_anlage_ek_step4',
        'cat_jobcenter_anlage_ek_step5',
        'cat_jobcenter_anlage_ek_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 9) Anlage KDU
    CategoryDefinition(
      id: 'jobcenter_anlage_kdu',
      labelKey: 'cat_jobcenter_anlage_kdu_label',
      summaryKey: 'cat_jobcenter_anlage_kdu_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage KDU',
        'Kosten der Unterkunft und Heizung',
        'Angaben zur Unterkunft',
        'Unterkunftskosten',
      ],
      decisiveKeywords: [
        'Kosten der Unterkunft und Heizung',
        'Gesamtmiete',
        'Heizkosten',
        'Nebenkosten',
        'Angaben zur Unterkunft',
        'Mietkosten',
      ],
      supportingKeywords: [
        'Mietvertrag',
        'Kaltmiete',
        'Warmmiete',
        'Heizkosten',
        'Nebenkosten',
        'Betriebskosten',
        'Wohnfläche',
        'Vermieter',
      ],
      weakNegativeKeywords: [
        'Anlage VM',
        'Anlage EK',
        'Hauptantrag',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'WBA',
        'Veränderungsmitteilung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_kdu_step1',
        'cat_jobcenter_anlage_kdu_step2',
        'cat_jobcenter_anlage_kdu_step3',
        'cat_jobcenter_anlage_kdu_step4',
        'cat_jobcenter_anlage_kdu_step5',
        'cat_jobcenter_anlage_kdu_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 10) Anlage VM
    CategoryDefinition(
      id: 'jobcenter_anlage_vm',
      labelKey: 'cat_jobcenter_anlage_vm_label',
      summaryKey: 'cat_jobcenter_anlage_vm_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage VM',
        'Angaben zum Vermögen',
        'Vermögenswerte',
        'Anlage Vermögen',
      ],
      decisiveKeywords: [
        'Konto- und Sparguthaben',
        'Bargeld',
        'Wertpapiere',
        'Kraftfahrzeug',
        'Vermögen im In- und Ausland',
        'Immobilienbesitz',
      ],
      supportingKeywords: [
        'Sparbuch',
        'Girokonto',
        'Bausparvertrag',
        'Fahrzeug',
        'Haus',
        'Grundstück',
        'Rückkaufswert',
        'Vermögen',
      ],
      weakNegativeKeywords: [
        'Anlage EK',
        'Anlage KDU',
        'Anlage EKS',
        'Veränderungsmitteilung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Arbeitsbescheinigung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_vm_step1',
        'cat_jobcenter_anlage_vm_step2',
        'cat_jobcenter_anlage_vm_step3',
        'cat_jobcenter_anlage_vm_step4',
        'cat_jobcenter_anlage_vm_step5',
        'cat_jobcenter_anlage_vm_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 11) Anlage EKS
    CategoryDefinition(
      id: 'jobcenter_anlage_eks',
      labelKey: 'cat_jobcenter_anlage_eks_label',
      summaryKey: 'cat_jobcenter_anlage_eks_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage EKS',
        'Angaben zum Einkommen aus selbständiger Tätigkeit',
        'vorläufige EKS',
        'abschließende EKS',
      ],
      decisiveKeywords: [
        'selbständige Tätigkeit',
        'Betriebseinnahmen',
        'Betriebsausgaben',
        'Gewinn',
        'voraussichtliches Einkommen',
        'abschließende Angaben zum Einkommen',
      ],
      supportingKeywords: [
        'Gewerbe',
        'Umsatz',
        'Ausgaben',
        'Einnahmen',
        'Gewinn',
        'Verlust',
        'selbständig',
        'freiberuflich',
      ],
      weakNegativeKeywords: [
        'Anlage EK',
        'Einkommensbescheinigung',
        'Arbeitsbescheinigung',
        'Veränderungsmitteilung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Hauptantrag',
        'Mitwirkung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_eks_step1',
        'cat_jobcenter_anlage_eks_step2',
        'cat_jobcenter_anlage_eks_step3',
        'cat_jobcenter_anlage_eks_step4',
        'cat_jobcenter_anlage_eks_step5',
        'cat_jobcenter_anlage_eks_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 12) Anlage WEP
    CategoryDefinition(
      id: 'jobcenter_anlage_wep',
      labelKey: 'cat_jobcenter_anlage_wep_label',
      summaryKey: 'cat_jobcenter_anlage_wep_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage WEP',
        'Weitere Person in der Bedarfsgemeinschaft',
        'Angaben zur weiteren Person',
        'weitere Person',
      ],
      decisiveKeywords: [
        'weitere Person in der Bedarfsgemeinschaft',
        'Angaben zur Person',
        'Person gehört zur Bedarfsgemeinschaft',
        'Familienstand',
        'Staatsangehörigkeit',
        'persönliche Daten der weiteren Person',
      ],
      supportingKeywords: [
        'Partner',
        'Personendaten',
        'Aufenthalt',
        'Familienstand',
        'Bedarfsgemeinschaft',
        'Name',
        'Vorname',
        'weitere Person',
      ],
      weakNegativeKeywords: [
        'Anlage HG',
        'Anlage VE',
        'Anlage KI',
        'Hauptantrag',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_wep_step1',
        'cat_jobcenter_anlage_wep_step2',
        'cat_jobcenter_anlage_wep_step3',
        'cat_jobcenter_anlage_wep_step4',
        'cat_jobcenter_anlage_wep_step5',
        'cat_jobcenter_anlage_wep_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 13) Anlage KI
    CategoryDefinition(
      id: 'jobcenter_anlage_ki',
      labelKey: 'cat_jobcenter_anlage_ki_label',
      summaryKey: 'cat_jobcenter_anlage_ki_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage KI',
        'Kinder unter 15 Jahren',
        'Angaben zu den Kindern',
        'Kind in der Bedarfsgemeinschaft',
      ],
      decisiveKeywords: [
        'Kinder unter 15 Jahren',
        'Angaben zum Kind',
        'Kind lebt im Haushalt',
        'Kindergeld',
        'Schule oder Kita',
        'minderjähriges Kind',
      ],
      supportingKeywords: [
        'Kind',
        'Kinder',
        'Sorgerecht',
        'Kindergeld',
        'Schule',
        'Betreuung',
        'Geburtsurkunde',
        'minderjährig',
      ],
      weakNegativeKeywords: [
        'Anlage WEP',
        'Anlage HG',
        'Anlage VE',
        'Hauptantrag',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_ki_step1',
        'cat_jobcenter_anlage_ki_step2',
        'cat_jobcenter_anlage_ki_step3',
        'cat_jobcenter_anlage_ki_step4',
        'cat_jobcenter_anlage_ki_step5',
        'cat_jobcenter_anlage_ki_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 14) Anlage HG
    CategoryDefinition(
      id: 'jobcenter_anlage_hg',
      labelKey: 'cat_jobcenter_anlage_hg_label',
      summaryKey: 'cat_jobcenter_anlage_hg_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage HG',
        'Haushaltsgemeinschaft',
        'Angaben zu den Haushaltsangehörigen',
        'Personen im Haushalt',
      ],
      decisiveKeywords: [
        'Haushaltsgemeinschaft',
        'Personen leben zusammen',
        'gemeinsame Wohnung',
        'Haushaltsangehörige',
        'Unterstützung im Haushalt',
        'Verwandte im Haushalt',
      ],
      supportingKeywords: [
        'Mitbewohner',
        'Eltern',
        'Verwandte',
        'Haushalt',
        'gemeinsame Wohnung',
        'zusammen wohnen',
        'Haushaltsangehörige',
        'Wohnsituation',
      ],
      weakNegativeKeywords: [
        'Anlage WEP',
        'Anlage VE',
        'Anlage KI',
        'Anlage KDU',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Hauptantrag',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_hg_step1',
        'cat_jobcenter_anlage_hg_step2',
        'cat_jobcenter_anlage_hg_step3',
        'cat_jobcenter_anlage_hg_step4',
        'cat_jobcenter_anlage_hg_step5',
        'cat_jobcenter_anlage_hg_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 15) Anlage VE
    CategoryDefinition(
      id: 'jobcenter_anlage_ve',
      labelKey: 'cat_jobcenter_anlage_ve_label',
      summaryKey: 'cat_jobcenter_anlage_ve_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage VE',
        'Verantwortungs- und Einstehensgemeinschaft',
        'leben Sie in einer Partnerschaft',
        'Partner im Haushalt',
      ],
      decisiveKeywords: [
        'Verantwortungs- und Einstehensgemeinschaft',
        'Partner',
        'gemeinsames Wirtschaften',
        'länger als ein Jahr zusammen',
        'gemeinsame Kinder',
        'gegenseitige Verantwortung',
      ],
      supportingKeywords: [
        'Partnerschaft',
        'zusammen wohnen',
        'gemeinsame Haushaltsführung',
        'Partner',
        'eheähnlich',
        'Verantwortung',
        'Einstehen',
        'gemeinsames Konto',
      ],
      weakNegativeKeywords: [
        'Anlage WEP',
        'Anlage HG',
        'Anlage KI',
        'Hauptantrag',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Arbeitsbescheinigung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_ve_step1',
        'cat_jobcenter_anlage_ve_step2',
        'cat_jobcenter_anlage_ve_step3',
        'cat_jobcenter_anlage_ve_step4',
        'cat_jobcenter_anlage_ve_step5',
        'cat_jobcenter_anlage_ve_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 16) Anlage SV
    CategoryDefinition(
      id: 'jobcenter_anlage_sv',
      labelKey: 'cat_jobcenter_anlage_sv_label',
      summaryKey: 'cat_jobcenter_anlage_sv_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage SV',
        'Angaben zur Sozialversicherung',
        'Kranken- und Pflegeversicherung',
        'Versicherungsschutz',
      ],
      decisiveKeywords: [
        'gesetzliche Krankenversicherung',
        'private Krankenversicherung',
        'Rentenversicherung',
        'Versicherungsnummer',
        'Krankenkasse',
        'Mitgliedschaft bei einer Krankenkasse',
      ],
      supportingKeywords: [
        'Krankenkasse',
        'Versicherung',
        'Sozialversicherung',
        'Rentenversicherungsnummer',
        'Mitgliedschaft',
        'Pflegeversicherung',
        'Versicherungsstatus',
        'versichert',
      ],
      weakNegativeKeywords: [
        'Anlage KI',
        'Anlage HG',
        'Anlage VE',
        'Anlage KDU',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_sv_step1',
        'cat_jobcenter_anlage_sv_step2',
        'cat_jobcenter_anlage_sv_step3',
        'cat_jobcenter_anlage_sv_step4',
        'cat_jobcenter_anlage_sv_step5',
        'cat_jobcenter_anlage_sv_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 17) Anlage UH1 / UH2 / UH3
    CategoryDefinition(
      id: 'jobcenter_anlage_uh',
      labelKey: 'cat_jobcenter_anlage_uh_label',
      summaryKey: 'cat_jobcenter_anlage_uh_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Unterhaltsansprüche',
        'Unterhalt',
        'Unterhaltspflicht',
        'Anlage UH',
      ],
      decisiveKeywords: [
        'Unterhaltsanspruch',
        'Unterhaltszahlungen',
        'unterhaltspflichtige Person',
        'Kindesunterhalt',
        'Ehegattenunterhalt',
        'getrennt lebend',
      ],
      supportingKeywords: [
        'Unterhalt',
        'Jugendamt',
        'Unterhaltsvorschuss',
        'Scheidung',
        'Vater des Kindes',
        'Unterhaltspflicht',
        'Trennung',
        'Zahlungen',
      ],
      weakNegativeKeywords: [
        'Anlage KI',
        'Anlage VE',
        'Anlage HG',
        'Hauptantrag',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Mitwirkung',
        'Arbeitsbescheinigung',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_uh_step1',
        'cat_jobcenter_anlage_uh_step2',
        'cat_jobcenter_anlage_uh_step3',
        'cat_jobcenter_anlage_uh_step4',
        'cat_jobcenter_anlage_uh_step5',
        'cat_jobcenter_anlage_uh_step6',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // 18) Anlage BB
    CategoryDefinition(
      id: 'jobcenter_anlage_bb',
      labelKey: 'cat_jobcenter_anlage_bb_label',
      summaryKey: 'cat_jobcenter_anlage_bb_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage BB',
        'besonderer Bedarf',
        'laufender besonderer Bedarf',
        'Angaben zum besonderen Bedarf',
      ],
      decisiveKeywords: [
        'besonderer Bedarf',
        'unabweisbarer Bedarf',
        'laufender besonderer Bedarf',
        'zusätzliche Kosten',
        'besondere Lebenssituation',
        'außergewöhnlicher Bedarf',
      ],
      supportingKeywords: [
        'Bedarf',
        'Nachweis',
        'zusätzliche Kosten',
        'besondere Situation',
        'Härtefall',
        'Begründung',
        'Ausgaben',
        'Antrag',
      ],
      weakNegativeKeywords: [
        'Anlage MEB',
        'Anlage UF',
        'Mitwirkung',
        'WBA',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Hauptantrag',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_bb_step1',
        'cat_jobcenter_anlage_bb_step2',
        'cat_jobcenter_anlage_bb_step3',
        'cat_jobcenter_anlage_bb_step4',
        'cat_jobcenter_anlage_bb_step5',
        'cat_jobcenter_anlage_bb_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 19) Anlage MEB
    CategoryDefinition(
      id: 'jobcenter_anlage_meb',
      labelKey: 'cat_jobcenter_anlage_meb_label',
      summaryKey: 'cat_jobcenter_anlage_meb_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage MEB',
        'medizinischer Mehrbedarf',
        'gesundheitsbedingter Mehrbedarf',
        'besondere Ernährung',
      ],
      decisiveKeywords: [
        'aus medizinischen Gründen',
        'kostenaufwändige Ernährung',
        'ärztliche Bescheinigung',
        'gesundheitlicher Mehrbedarf',
        'medizinisch begründeter Bedarf',
        'Mehrbedarf wird beantragt',
      ],
      supportingKeywords: [
        'Arzt',
        'Attest',
        'Krankheit',
        'Diagnose',
        'Ernährung',
        'Mehrbedarf',
        'gesundheitlich',
        'Behandlung',
      ],
      weakNegativeKeywords: [
        'Anlage BB',
        'Anlage UF',
        'Anlage SV',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Hauptantrag',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_meb_step1',
        'cat_jobcenter_anlage_meb_step2',
        'cat_jobcenter_anlage_meb_step3',
        'cat_jobcenter_anlage_meb_step4',
        'cat_jobcenter_anlage_meb_step5',
        'cat_jobcenter_anlage_meb_step6',
      ],
      riskLevel: RiskLevel.low,
    ),

    // 20) Anlage UF
    CategoryDefinition(
      id: 'jobcenter_anlage_uf',
      labelKey: 'cat_jobcenter_anlage_uf_label',
      summaryKey: 'cat_jobcenter_anlage_uf_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Anlage UF',
        'Unfall',
        'Schadensersatz',
        'Ersatzanspruch',
      ],
      decisiveKeywords: [
        'aufgrund eines Unfalls',
        'Schadensersatzanspruch',
        'Schmerzensgeld',
        'Entschädigungszahlung',
        'Anspruch gegen Dritte',
        'Versicherung zahlt',
      ],
      supportingKeywords: [
        'Unfallversicherung',
        'Haftpflicht',
        'Ersatz',
        'Zahlung',
        'Schaden',
        'Anspruch',
        'Entschädigung',
        'Unfall',
      ],
      weakNegativeKeywords: [
        'Anlage VM',
        'Anlage BB',
        'Mitwirkung',
        'Veränderungsmitteilung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Hauptantrag',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_uf_step1',
        'cat_jobcenter_anlage_uf_step2',
        'cat_jobcenter_anlage_uf_step3',
        'cat_jobcenter_anlage_uf_step4',
        'cat_jobcenter_anlage_uf_step5',
        'cat_jobcenter_anlage_uf_step6',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // 21) AH – Hinweise
    CategoryDefinition(
      id: 'jobcenter_hinweise',
      labelKey: 'cat_jobcenter_hinweise_label',
      summaryKey: 'cat_jobcenter_hinweise_summary',
      mainCategory: MainCategory.categoryJobcenter,
      headerKeywords: [
        'Hinweise',
        'Ausfüllhinweise',
        'wichtige Hinweise',
        'Erläuterungen',
      ],
      decisiveKeywords: [
        'bitte beachten Sie',
        'Ausfüllhinweise',
        'Erläuterungen',
        'wichtige Informationen',
        'Hinweise zum Antrag',
        'allgemeine Informationen',
      ],
      supportingKeywords: [
        'Hinweis',
        'Information',
        'Erklärung',
        'Erläuterung',
        'Merkblatt',
        'beachten',
        'Ausfüllhilfe',
        'Informationen',
      ],
      weakNegativeKeywords: [
        'Hauptantrag',
        'WBA',
        'Anlage EK',
        'Mitwirkung',
      ],
      strongNegativeKeywords: [
        'Bewilligungsbescheid',
        'Einladung',
        'Aufforderung zur Mitwirkung',
        'Änderungsbescheid',
      ],
      nextStepKeys: [
        'cat_jobcenter_hinweise_step1',
        'cat_jobcenter_hinweise_step2',
        'cat_jobcenter_hinweise_step3',
        'cat_jobcenter_hinweise_step4',
        'cat_jobcenter_hinweise_step5',
        'cat_jobcenter_hinweise_step6',
      ],
      riskLevel: RiskLevel.low,
    ),
  ];
}
