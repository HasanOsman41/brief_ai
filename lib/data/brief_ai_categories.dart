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
/// 67 sub-categories across 10 main groups.
/// Jobcenter section: BriefAI_Jobcenter_Schluesselwoerter_ohne_Konflikte.docx

// ignore_for_file: prefer_single_quotes

import '../models/category_definition.dart';
import '../models/document_result.dart';

class BriefAiCategories {
  BriefAiCategories._();

  // ───────────────────────────────────────────────────────────────────────────
  // MAIN GROUPS
  // Labels for the 10 top-level buckets shown in the app UI.
  // Sub-categories reference these via their [mainCategory] field.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<MainCategoryDefinition> mainGroups = [
    MainCategoryDefinition(
      value: MainCategory.categoryJobcenter,
      labelKey: 'cat_categoryJobcenter_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryAuslaenderbehoerde,
      labelKey: 'cat_categoryAuslaenderbehoerde_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryKrankenkasse,
      labelKey: 'cat_categoryKrankenkasse_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryFinanzamt,
      labelKey: 'cat_categoryFinanzamt_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryBank,
      labelKey: 'cat_categoryBank_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryInsurance,
      labelKey: 'cat_categoryInsurance_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryRent,
      labelKey: 'cat_categoryRent_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryBills,
      labelKey: 'cat_categoryBills_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryContracts,
      labelKey: 'cat_categoryContracts_label',
    ),
    MainCategoryDefinition(
      value: MainCategory.categoryOther,
      labelKey: 'cat_categoryOther_label',
    ),
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // SUB-CATEGORIES
  // Every entry declares its own [mainCategory] so the full picture of any
  // category is visible in one place. The analyzer reads only this list.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<CategoryDefinition> all = [
    // ─────────────────────────────────────────────────────────────────────
    // JOBCENTER  (22 categories – updated from dataset file)
    // ─────────────────────────────────────────────────────────────────────

    // ── Core forms ────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_termin',
      labelKey: 'cat_jobcenter_termin_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Einladung zum Termin',
        'bitte erscheinen Sie',
        'Termin wahrnehmen',
      ],
      supportingKeywords: ['Jobcenter', 'Termin', 'Personalausweis', 'Uhrzeit'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid', 'Steuerbescheid'],
      nextStepKeys: [
        'cat_jobcenter_termin_step1',
        'cat_jobcenter_termin_step2',
        'cat_jobcenter_termin_step3',
        'cat_jobcenter_termin_step4',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_mitwirkung',
      labelKey: 'cat_jobcenter_mitwirkung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Aufforderung zur Mitwirkung',
        'Mitwirkungspflicht',
        'fristgerecht eingehen',
      ],
      supportingKeywords: ['Jobcenter', 'Unterlagen', 'Nachweis', 'einreichen'],
      negativeKeywords: ['Inkasso', 'Steuerbescheid'],
      nextStepKeys: [
        'cat_jobcenter_mitwirkung_step1',
        'cat_jobcenter_mitwirkung_step2',
        'cat_jobcenter_mitwirkung_step3',
        'cat_jobcenter_mitwirkung_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'jobcenter_hauptantrag',
      labelKey: 'cat_jobcenter_hauptantrag_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Hauptantrag',
        'Antrag auf Bürgergeld',
        'Leistungen nach dem SGB II',
      ],
      supportingKeywords: [
        'antragstellende Person',
        'Bedarfsgemeinschaft',
        'erforderliche Anlagen',
      ],
      negativeKeywords: ['Weiterbewilligungsantrag', 'WBA', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_hauptantrag_step1',
        'cat_jobcenter_hauptantrag_step2',
        'cat_jobcenter_hauptantrag_step3',
        'cat_jobcenter_hauptantrag_step4',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_weiterbewilligung',
      labelKey: 'cat_jobcenter_weiterbewilligung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Weiterbewilligungsantrag',
        'WBA',
        'Antrag auf Weiterbewilligung des Bürgergeldes',
      ],
      supportingKeywords: [
        'Bewilligungszeitraum',
        'Ende des laufenden Bewilligungszeitraumes',
        'weitere Bewilligung',
      ],
      negativeKeywords: ['Hauptantrag', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_weiterbewilligung_step1',
        'cat_jobcenter_weiterbewilligung_step2',
        'cat_jobcenter_weiterbewilligung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_veraenderung',
      labelKey: 'cat_jobcenter_veraenderung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Veränderungsmitteilung',
        'VÄM',
        'Veränderungsmitteilung bei Bezug von Bürgergeld',
      ],
      supportingKeywords: [
        'wichtige Änderungen',
        'Bankverbindung',
        'Wohnsituation',
        'Änderung der Verhältnisse',
      ],
      negativeKeywords: ['Inkasso', 'Mahnbescheid'],
      nextStepKeys: [
        'cat_jobcenter_veraenderung_step1',
        'cat_jobcenter_veraenderung_step2',
        'cat_jobcenter_veraenderung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_ausfuellhinweise',
      labelKey: 'cat_jobcenter_ausfuellhinweise_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Ausfüllhinweise',
        'Hinweise zur Beantragung von Bürgergeld',
      ],
      supportingKeywords: [
        'jobcenter.digital',
        'Erklärvideos zum Bürgergeld',
        'Hinweise zum Antrag',
      ],
      negativeKeywords: ['Hauptantrag', 'Weiterbewilligungsantrag', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_ausfuellhinweise_step1',
        'cat_jobcenter_ausfuellhinweise_step2',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ── Anlagen (Attachments) ─────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_anlage_wep',
      labelKey: 'cat_jobcenter_anlage_wep_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage WEP',
        'weitere Person ab 15 Jahren',
        'weitere Person in der Bedarfsgemeinschaft',
      ],
      supportingKeywords: [
        'Personenidentifikationsnummer',
        'Ausländerzentralregisternummer',
        'Kranken- und Pflegeversicherung',
      ],
      negativeKeywords: ['Kind unter 15', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_wep_step1',
        'cat_jobcenter_anlage_wep_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ki',
      labelKey: 'cat_jobcenter_anlage_ki_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage KI', 'Kind unter 15 Jahren'],
      supportingKeywords: [
        'Kindergeld',
        'Unterhaltsvorschuss',
        'Schülerin',
        'Schüler',
      ],
      negativeKeywords: ['Kindesunterhalt', 'Anlage WEP', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_ki_step1',
        'cat_jobcenter_anlage_ki_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_hg',
      labelKey: 'cat_jobcenter_anlage_hg_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage HG', 'Haushaltsgemeinschaft'],
      supportingKeywords: [
        'Verwandte',
        'Verschwägerte',
        'finanzielle Unterstützung',
      ],
      negativeKeywords: [
        'Verantwortungs- und Einstehensgemeinschaft',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_hg_step1',
        'cat_jobcenter_anlage_hg_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ve',
      labelKey: 'cat_jobcenter_anlage_ve_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage VE',
        'Verantwortungs- und Einstehensgemeinschaft',
      ],
      supportingKeywords: [
        'nicht verwandte Person',
        'Partnerin',
        'Partner',
        'gemeinsam ein Kind',
      ],
      negativeKeywords: ['Haushaltsgemeinschaft', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_ve_step1',
        'cat_jobcenter_anlage_ve_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ek',
      labelKey: 'cat_jobcenter_anlage_ek_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage EK', 'Anlage zum Einkommen'],
      supportingKeywords: [
        'Einkommensnachweise',
        'Person der Bedarfsgemeinschaft ab 15 Jahren',
        'Bruttoeinkommen',
        'Gehaltsabrechnung',
      ],
      negativeKeywords: [
        'selbständiger',
        'freiberuflicher Tätigkeit',
        'Betriebsausgaben',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_ek_step1',
        'cat_jobcenter_anlage_ek_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_vm',
      labelKey: 'cat_jobcenter_anlage_vm_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage VM', 'Selbstauskunft über das Vermögen'],
      supportingKeywords: [
        'Vermögensverhältnisse',
        'Geldanlagen',
        'Kryptowährungen',
        'Schmuck',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_vm_step1',
        'cat_jobcenter_anlage_vm_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_kdu',
      labelKey: 'cat_jobcenter_anlage_kdu_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage KDU', 'Bedarfe für Unterkunft und Heizung'],
      supportingKeywords: [
        'Grundmiete',
        'Nebenkosten',
        'Heizkosten',
        'Wohnen im Eigentum',
      ],
      negativeKeywords: [
        'Mietbescheinigung',
        'Vermieterbescheinigung',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_kdu_step1',
        'cat_jobcenter_anlage_kdu_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_eks',
      labelKey: 'cat_jobcenter_anlage_eks_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage EKS',
        'Einkommen aus selbständiger',
        'freiberuflicher Tätigkeit',
      ],
      supportingKeywords: [
        'vorläufige Erklärung',
        'abschließende Erklärung',
        'Betriebsausgaben',
        'Umsatzsteuerpflicht',
      ],
      negativeKeywords: ['Anlage EK', 'Anlage zum Einkommen', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_eks_step1',
        'cat_jobcenter_anlage_eks_step2',
        'cat_jobcenter_anlage_eks_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_meb',
      labelKey: 'cat_jobcenter_anlage_meb_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage MEB',
        'Mehrbedarf für kostenaufwändige Ernährung',
      ],
      supportingKeywords: [
        'ärztliche Bescheinigung',
        'medizinisch notwendige Kostform',
        'Erkrankung',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_meb_step1',
        'cat_jobcenter_anlage_meb_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_sv',
      labelKey: 'cat_jobcenter_anlage_sv_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage SV'],
      supportingKeywords: [
        'Kranken- und Pflegeversicherung',
        'privat krankenversichert',
        'Basistarif',
        'Zuschuss zu den Beiträgen',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_sv_step1',
        'cat_jobcenter_anlage_sv_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_bb',
      labelKey: 'cat_jobcenter_anlage_bb_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage BB', 'unabweisbarer besonderer Bedarf'],
      supportingKeywords: ['Kostenvoranschlag', 'Vorschuss', 'Quittungen'],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_bb_step1',
        'cat_jobcenter_anlage_bb_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uf',
      labelKey: 'cat_jobcenter_anlage_uf_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage UF', 'Schadensereignis'],
      supportingKeywords: [
        'Unfallbericht',
        'Haftpflichtversicherung',
        'Schadensnummer',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_uf_step1',
        'cat_jobcenter_anlage_uf_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ── Unterhalt (Maintenance) ────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_anlage_uh1',
      labelKey: 'cat_jobcenter_anlage_uh1_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage UH1',
        'Trennungsunterhalt',
        'nachehelicher Unterhalt',
        'nachpartnerschaftlicher Unterhalt',
      ],
      supportingKeywords: [
        'dauernd getrennt lebend',
        'Scheidung',
        'schriftliche Vereinbarung',
      ],
      negativeKeywords: ['Kindesunterhalt', 'Schwangerschaft', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_uh1_step1',
        'cat_jobcenter_anlage_uh1_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uh2',
      labelKey: 'cat_jobcenter_anlage_uh2_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Anlage UH2',
        'Unterhaltsansprüche aufgrund von Schwangerschaft',
      ],
      supportingKeywords: [
        'voraussichtlicher Entbindungstermin',
        'Kindsvater',
        'Vaterschaftsanerkennung',
      ],
      negativeKeywords: ['Trennungsunterhalt', 'Kindesunterhalt', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_anlage_uh2_step1',
        'cat_jobcenter_anlage_uh2_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uh3',
      labelKey: 'cat_jobcenter_anlage_uh3_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Anlage UH3', 'Prüfung von Kindesunterhalt'],
      supportingKeywords: [
        'unterhaltsberechtigte Person',
        'Elternteil außerhalb der Bedarfsgemeinschaft',
        'Unterhaltsvorschuss',
        'Kindesunterhalt',
      ],
      negativeKeywords: [
        'Kind unter 15 Jahren',
        'Trennungsunterhalt',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_jobcenter_anlage_uh3_step1',
        'cat_jobcenter_anlage_uh3_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ── Employer-issued forms ─────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_einkommensbescheinigung',
      labelKey: 'cat_jobcenter_einkommensbescheinigung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Einkommensbescheinigung',
        'Nachweis über die Höhe des Arbeitsentgelts',
      ],
      supportingKeywords: [
        'nur durch die Arbeitgeberin',
        'nur durch den Arbeitgeber auszufüllen',
        'Arbeitsentgelt',
        'Urkunde',
      ],
      negativeKeywords: ['Anlage EK', 'Selbständige', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_einkommensbescheinigung_step1',
        'cat_jobcenter_einkommensbescheinigung_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_arbeitsbescheinigung',
      labelKey: 'cat_jobcenter_arbeitsbescheinigung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: [
        'Arbeitsbescheinigung',
        '§ 57 Zweites Buch Sozialgesetzbuch (SGB II)',
      ],
      supportingKeywords: [
        'nur durch die Arbeitgeberin',
        'nur durch den Arbeitgeber auszufüllen',
        'Beschäftigungsverhältnis',
      ],
      negativeKeywords: ['Einkommensbescheinigung', 'Anlage EK', 'Inkasso'],
      nextStepKeys: [
        'cat_jobcenter_arbeitsbescheinigung_step1',
        'cat_jobcenter_arbeitsbescheinigung_step2',
        'cat_jobcenter_arbeitsbescheinigung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_mietbescheinigung',
      labelKey: 'cat_jobcenter_mietbescheinigung_label',
      mainCategory: MainCategory.categoryJobcenter,
      decisiveKeywords: ['Mietbescheinigung', 'Vermieterbescheinigung'],
      supportingKeywords: [
        'Vermieter',
        'Grundmiete',
        'Nebenkosten',
        'Wohnfläche',
      ],
      negativeKeywords: [
        'Bedarfe für Unterkunft und Heizung',
        'Anlage KDU',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_jobcenter_mietbescheinigung_step1',
        'cat_jobcenter_mietbescheinigung_step2',
        'cat_jobcenter_mietbescheinigung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // AUSLÄNDERBEHÖRDE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'auslaender_termin',
      labelKey: 'cat_auslaender_termin_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'Terminbestätigung',
        'Einladung zur persönlichen Vorsprache',
        'persönlich erscheinen',
      ],
      supportingKeywords: [
        'Ausländerbehörde',
        'Termin',
        'Reisepass',
        'Uhrzeit',
        'bitte bringen Sie',
      ],
      negativeKeywords: [
        'liegt zur Abholung bereit',
        'Dokumentenausgabebox',
        'Inkasso',
      ],
      nextStepKeys: [
        'cat_auslaender_termin_step1',
        'cat_auslaender_termin_step2',
        'cat_auslaender_termin_step3',
        'cat_auslaender_termin_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_unterlagen',
      labelKey: 'cat_auslaender_unterlagen_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'Aufforderung zur Vorlage von Unterlagen',
        'Nachforderung von Unterlagen',
        'fehlende Unterlagen',
      ],
      supportingKeywords: [
        'Ausländerbehörde',
        'bitte reichen Sie ein',
        'bis spätestens',
        'Nachweis',
        'Kopie des Reisepasses',
      ],
      negativeKeywords: ['Terminbestätigung', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_unterlagen_step1',
        'cat_auslaender_unterlagen_step2',
        'cat_auslaender_unterlagen_step3',
        'cat_auslaender_unterlagen_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_verlaengerung',
      labelKey: 'cat_auslaender_verlaengerung_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'Verlängerung des Aufenthaltstitels',
        'läuft bald ab',
        'vor Ablauf',
      ],
      supportingKeywords: [
        'Aufenthaltserlaubnis',
        'gültig bis',
        'Antrag stellen',
        'rechtzeitig',
        'Verlängerung',
      ],
      negativeKeywords: ['Erstantrag', 'Erteilung', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_verlaengerung_step1',
        'cat_auslaender_verlaengerung_step2',
        'cat_auslaender_verlaengerung_step3',
        'cat_auslaender_verlaengerung_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_bewilligung',
      labelKey: 'cat_auslaender_bewilligung_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'stattgegeben',
        'wird erteilt',
        'Bewilligungsbescheid',
      ],
      supportingKeywords: ['Aufenthaltserlaubnis', 'genehmigt', 'Erteilung'],
      negativeKeywords: ['abgelehnt', 'wird nicht erteilt', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_bewilligung_step1',
        'cat_auslaender_bewilligung_step2',
        'cat_auslaender_bewilligung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'auslaender_ablehnung',
      labelKey: 'cat_auslaender_ablehnung_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'Ablehnungsbescheid',
        'abgelehnt',
        'wird nicht erteilt',
      ],
      supportingKeywords: [
        'Ausländerbehörde',
        'fehlende Unterlagen',
        'Voraussetzungen nicht erfüllt',
      ],
      negativeKeywords: ['stattgegeben', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_ablehnung_step1',
        'cat_auslaender_ablehnung_step2',
        'cat_auslaender_ablehnung_step3',
        'cat_auslaender_ablehnung_step4',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'auslaender_fiktionsbescheinigung',
      labelKey: 'cat_auslaender_fiktionsbescheinigung_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'Fiktionsbescheinigung',
        'bis zu unserer Entscheidung weiterhin',
        'Fortgeltung',
      ],
      supportingKeywords: [
        'weiterhin gültig',
        'vorübergehend',
        'Bearbeitung noch nicht abgeschlossen',
      ],
      negativeKeywords: ['stattgegeben', 'abgelehnt', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_fiktionsbescheinigung_step1',
        'cat_auslaender_fiktionsbescheinigung_step2',
        'cat_auslaender_fiktionsbescheinigung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'auslaender_abholung_eat',
      labelKey: 'cat_auslaender_abholung_eat_label',
      mainCategory: MainCategory.categoryAuslaenderbehoerde,
      decisiveKeywords: [
        'liegt zur Abholung bereit',
        'elektronischer Aufenthaltstitel',
        'Dokumentenausgabebox',
      ],
      supportingKeywords: ['eAT', 'Abholung', 'Reisepass mitbringen'],
      negativeKeywords: ['Termin', 'Inkasso'],
      nextStepKeys: [
        'cat_auslaender_abholung_eat_step1',
        'cat_auslaender_abholung_eat_step2',
        'cat_auslaender_abholung_eat_step3',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // KRANKENKASSE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'krankenkasse_bescheinigung',
      labelKey: 'cat_krankenkasse_bescheinigung_label',
      mainCategory: MainCategory.categoryKrankenkasse,
      decisiveKeywords: [
        'Versicherungsbescheinigung',
        'Mitgliedsbescheinigung',
        'hiermit bestätigen wir',
      ],
      supportingKeywords: [
        'Krankenkasse',
        'Versichertennummer',
        'versichert seit',
        'Mitglied',
      ],
      negativeKeywords: ['Beitrag', 'Zahlungsfrist', 'Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_krankenkasse_bescheinigung_step1',
        'cat_krankenkasse_bescheinigung_step2',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'krankenkasse_beitrag',
      labelKey: 'cat_krankenkasse_beitrag_label',
      mainCategory: MainCategory.categoryKrankenkasse,
      decisiveKeywords: [
        'Beitragsbescheid',
        'Beitragshöhe',
        'Zahlungsfrist Beitrag',
      ],
      supportingKeywords: [
        'Krankenkasse',
        'Beitrag',
        'überweisen',
        'monatlich',
      ],
      negativeKeywords: ['Mitgliedsbescheinigung', 'Inkasso', 'Mahnung'],
      nextStepKeys: [
        'cat_krankenkasse_beitrag_step1',
        'cat_krankenkasse_beitrag_step2',
        'cat_krankenkasse_beitrag_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'krankenkasse_mahnung',
      labelKey: 'cat_krankenkasse_mahnung_label',
      mainCategory: MainCategory.categoryKrankenkasse,
      decisiveKeywords: [
        'Beitragsrückstand',
        'Mahnung Krankenkasse',
        'offener Beitrag Krankenkasse',
      ],
      supportingKeywords: [
        'Krankenkasse',
        'Rückstand',
        'Zahlungsverzug',
        'Mahnung',
      ],
      negativeKeywords: ['Mitgliedsbescheinigung', 'Inkasso Justiz'],
      nextStepKeys: [
        'cat_krankenkasse_mahnung_step1',
        'cat_krankenkasse_mahnung_step2',
        'cat_krankenkasse_mahnung_step3',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'krankenkasse_krankengeld',
      labelKey: 'cat_krankenkasse_krankengeld_label',
      mainCategory: MainCategory.categoryKrankenkasse,
      decisiveKeywords: [
        'Krankengeld',
        'Arbeitsunfähigkeit',
        'Arbeitsunfähigkeitsbescheinigung',
      ],
      supportingKeywords: ['Krankenkasse', 'AU', 'krank', 'Lohnfortzahlung'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_krankenkasse_krankengeld_step1',
        'cat_krankenkasse_krankengeld_step2',
        'cat_krankenkasse_krankengeld_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'krankenkasse_kuendigung',
      labelKey: 'cat_krankenkasse_kuendigung_label',
      mainCategory: MainCategory.categoryKrankenkasse,
      decisiveKeywords: [
        'Kassenwechsel',
        'Kündigung Krankenkasse',
        'Mitgliedschaft endet',
      ],
      supportingKeywords: [
        'Krankenkasse',
        'Kündigung',
        'neue Krankenkasse',
        'wechseln',
      ],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_krankenkasse_kuendigung_step1',
        'cat_krankenkasse_kuendigung_step2',
        'cat_krankenkasse_kuendigung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // FINANZAMT
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'finanzamt_steuerbescheid',
      labelKey: 'cat_finanzamt_steuerbescheid_label',
      mainCategory: MainCategory.categoryFinanzamt,
      decisiveKeywords: [
        'Steuerbescheid',
        'festgesetzte Steuer',
        'Einkommensteuerbescheid',
      ],
      supportingKeywords: [
        'Finanzamt',
        'Nachzahlung',
        'Steuerjahr',
        'Betrag überweisen',
      ],
      negativeKeywords: ['Erstattung', 'Inkasso', 'Mahnung'],
      nextStepKeys: [
        'cat_finanzamt_steuerbescheid_step1',
        'cat_finanzamt_steuerbescheid_step2',
        'cat_finanzamt_steuerbescheid_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'finanzamt_erstattung',
      labelKey: 'cat_finanzamt_erstattung_label',
      mainCategory: MainCategory.categoryFinanzamt,
      decisiveKeywords: [
        'Erstattung',
        'Rückzahlung Steuer',
        'Steuererstattung',
      ],
      supportingKeywords: [
        'Finanzamt',
        'Steuerbescheid',
        'Betrag wird überwiesen',
      ],
      negativeKeywords: ['Nachzahlung', 'Inkasso', 'Mahnung'],
      nextStepKeys: [
        'cat_finanzamt_erstattung_step1',
        'cat_finanzamt_erstattung_step2',
        'cat_finanzamt_erstattung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'finanzamt_abgabe',
      labelKey: 'cat_finanzamt_abgabe_label',
      mainCategory: MainCategory.categoryFinanzamt,
      decisiveKeywords: [
        'Abgabe der Steuererklärung',
        'Aufforderung Steuererklärung',
      ],
      supportingKeywords: ['Finanzamt', 'Frist', 'Steuerjahr', 'einreichen'],
      negativeKeywords: ['Inkasso', 'Mahnung'],
      nextStepKeys: [
        'cat_finanzamt_abgabe_step1',
        'cat_finanzamt_abgabe_step2',
        'cat_finanzamt_abgabe_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'finanzamt_verspaetung',
      labelKey: 'cat_finanzamt_verspaetung_label',
      mainCategory: MainCategory.categoryFinanzamt,
      decisiveKeywords: ['Verspätungszuschlag', 'verspätet eingereicht'],
      supportingKeywords: ['Finanzamt', 'Zuschlag', 'Steuererklärung'],
      negativeKeywords: ['Inkasso'],
      nextStepKeys: [
        'cat_finanzamt_verspaetung_step1',
        'cat_finanzamt_verspaetung_step2',
        'cat_finanzamt_verspaetung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // BANK
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'bank_kontoauszug',
      labelKey: 'cat_bank_kontoauszug_label',
      mainCategory: MainCategory.categoryBank,
      decisiveKeywords: [
        'Kontoauszug',
        'Kontostand',
        'Buchungstag',
        'Kontobewegungen',
      ],
      supportingKeywords: [
        'IBAN',
        'Überweisung',
        'Lastschrift',
        'Gutschrift',
        'Valuta',
      ],
      negativeKeywords: ['Rechnung', 'Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_bank_kontoauszug_step1',
        'cat_bank_kontoauszug_step2',
        'cat_bank_kontoauszug_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'bank_sicherheitswarnung',
      labelKey: 'cat_bank_sicherheitswarnung_label',
      mainCategory: MainCategory.categoryBank,
      decisiveKeywords: [
        'Sicherheitswarnung',
        'ungewöhnliche Aktivität',
        'Kontosicherheit',
      ],
      supportingKeywords: ['Konto', 'verdächtig', 'Überprüfung', 'Bank'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepKeys: [
        'cat_bank_sicherheitswarnung_step1',
        'cat_bank_sicherheitswarnung_step2',
        'cat_bank_sicherheitswarnung_step3',
        'cat_bank_sicherheitswarnung_step4',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'bank_ueberweisung',
      labelKey: 'cat_bank_ueberweisung_label',
      mainCategory: MainCategory.categoryBank,
      decisiveKeywords: [
        'Überweisung erfolgreich',
        'Überweisungsauftrag',
        'Empfänger',
      ],
      supportingKeywords: ['IBAN', 'Betrag', 'SEPA', 'ausgeführt'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: ['cat_bank_ueberweisung_step1'],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'bank_ruecklastschrift',
      labelKey: 'cat_bank_ruecklastschrift_label',
      mainCategory: MainCategory.categoryBank,
      decisiveKeywords: [
        'Rücklastschrift',
        'nicht durchgeführt',
        'Kontodeckung',
      ],
      supportingKeywords: ['Lastschrift', 'Abbuchung', 'Betrag'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepKeys: [
        'cat_bank_ruecklastschrift_step1',
        'cat_bank_ruecklastschrift_step2',
        'cat_bank_ruecklastschrift_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'bank_ueberziehung',
      labelKey: 'cat_bank_ueberziehung_label',
      mainCategory: MainCategory.categoryBank,
      decisiveKeywords: ['Kontoüberziehung', 'negativer Saldo', 'Überziehung'],
      supportingKeywords: ['Konto', 'Saldo', 'ausgleichen'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepKeys: [
        'cat_bank_ueberziehung_step1',
        'cat_bank_ueberziehung_step2',
        'cat_bank_ueberziehung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // RECHNUNG / MAHNUNG / INKASSO / GERICHT
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'rechnung',
      labelKey: 'cat_rechnung_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: [
        'Rechnungsnummer',
        'Rechnungsdatum',
        'zahlbar bis',
        'Gesamtbetrag',
      ],
      supportingKeywords: [
        'Rechnung',
        'Leistung',
        'Betrag',
        'Überweisung',
        'Fälligkeitsdatum',
      ],
      negativeKeywords: [
        'Mahnung',
        'Inkasso',
        'Mahnbescheid',
        'Vollstreckungsbescheid',
      ],
      nextStepKeys: [
        'cat_rechnung_step1',
        'cat_rechnung_step2',
        'cat_rechnung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'zahlungserinnerung',
      labelKey: 'cat_zahlungserinnerung_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: [
        'Zahlungserinnerung',
        'offener Betrag',
        'kein Zahlungseingang',
      ],
      supportingKeywords: ['Rechnung', 'bitte zahlen', 'innerhalb von'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid'],
      nextStepKeys: [
        'cat_zahlungserinnerung_step1',
        'cat_zahlungserinnerung_step2',
        'cat_zahlungserinnerung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'mahnung',
      labelKey: 'cat_mahnung_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: ['Mahnung', 'offene Forderung', 'Zahlungsfrist'],
      supportingKeywords: ['kein Zahlungseingang', 'Betrag', 'zahlen'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepKeys: [
        'cat_mahnung_step1',
        'cat_mahnung_step2',
        'cat_mahnung_step3',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'letzte_mahnung',
      labelKey: 'cat_letzte_mahnung_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: ['Letzte Mahnung', 'letzte Frist'],
      supportingKeywords: ['spätestens', 'Inkasso', 'offener Betrag'],
      negativeKeywords: ['Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepKeys: [
        'cat_letzte_mahnung_step1',
        'cat_letzte_mahnung_step2',
        'cat_letzte_mahnung_step3',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'inkasso',
      labelKey: 'cat_inkasso_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: [
        'Inkasso',
        'Inkassoforderung',
        'Hauptforderung',
        'Inkassokosten',
      ],
      supportingKeywords: ['Gesamtforderung', 'Auftraggeber', 'Inkassobüro'],
      negativeKeywords: ['Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepKeys: [
        'cat_inkasso_step1',
        'cat_inkasso_step2',
        'cat_inkasso_step3',
        'cat_inkasso_step4',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'mahnbescheid',
      labelKey: 'cat_mahnbescheid_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: ['Mahnbescheid', 'Widerspruch', 'Gericht'],
      supportingKeywords: ['Hauptforderung', 'Zustellung', 'zwei Wochen'],
      negativeKeywords: ['Vollstreckungsbescheid'],
      nextStepKeys: [
        'cat_mahnbescheid_step1',
        'cat_mahnbescheid_step2',
        'cat_mahnbescheid_step3',
        'cat_mahnbescheid_step4',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'vollstreckungsbescheid',
      labelKey: 'cat_vollstreckungsbescheid_label',
      mainCategory: MainCategory.categoryBills,
      decisiveKeywords: [
        'Vollstreckungsbescheid',
        'Zwangsvollstreckung',
        'Gerichtsvollzieher',
        'Pfändung',
      ],
      supportingKeywords: ['Einspruch', 'vollstreckbar', 'Mahnbescheid'],
      negativeKeywords: [],
      nextStepKeys: [
        'cat_vollstreckungsbescheid_step1',
        'cat_vollstreckungsbescheid_step2',
        'cat_vollstreckungsbescheid_step3',
      ],
      riskLevel: RiskLevel.critical,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // WOHNEN / MIETE / KAUTION
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'miete_kuendigung',
      labelKey: 'cat_miete_kuendigung_label',
      mainCategory: MainCategory.categoryRent,
      decisiveKeywords: [
        'Kündigung Mietvertrag',
        'kündigen wir den Mietvertrag',
        'fristlose Kündigung',
        'Mietverhältnis kündigen',
        'kündigen wir das Mietverhältnis',
      ],
      supportingKeywords: ['Wohnung', 'Mietende', 'Vermieter', 'Mieter'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_miete_kuendigung_step1',
        'cat_miete_kuendigung_step2',
        'cat_miete_kuendigung_step3',
        'cat_miete_kuendigung_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'mietvertrag',
      labelKey: 'cat_mietvertrag_label',
      mainCategory: MainCategory.categoryRent,
      decisiveKeywords: ['Mietvertrag', 'Kaltmiete', 'Warmmiete', 'Mietbeginn'],
      supportingKeywords: ['Mieter', 'Vermieter', 'Wohnung', 'Nebenkosten'],
      negativeKeywords: [
        'Mahnung',
        'Inkasso',
        'Kontoauszug',
        'Kündigung',
        'kündigen',
      ],
      nextStepKeys: [
        'cat_mietvertrag_step1',
        'cat_mietvertrag_step2',
        'cat_mietvertrag_step3',
        'cat_mietvertrag_step4',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'nebenkostenabrechnung',
      labelKey: 'cat_nebenkostenabrechnung_label',
      mainCategory: MainCategory.categoryRent,
      decisiveKeywords: [
        'Nebenkostenabrechnung',
        'Betriebskostenabrechnung',
        'Nachzahlung Nebenkosten',
        'Abrechnungszeitraum',
      ],
      supportingKeywords: ['Heizung', 'Wasser', 'Vorauszahlung', 'Abrechnung'],
      negativeKeywords: ['Steuerbescheid', 'Inkasso', 'Mahnbescheid'],
      nextStepKeys: [
        'cat_nebenkostenabrechnung_step1',
        'cat_nebenkostenabrechnung_step2',
        'cat_nebenkostenabrechnung_step3',
        'cat_nebenkostenabrechnung_step4',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'mieterhoehung',
      labelKey: 'cat_mieterhoehung_label',
      mainCategory: MainCategory.categoryRent,
      decisiveKeywords: ['Mieterhöhung', 'monatliche Miete', 'erhöht sich'],
      supportingKeywords: ['Mietvertrag', 'neue Miethöhe', 'Vermieter'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_mieterhoehung_step1',
        'cat_mieterhoehung_step2',
        'cat_mieterhoehung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'kaution',
      labelKey: 'cat_kaution_label',
      mainCategory: MainCategory.categoryRent,
      decisiveKeywords: [
        'Mietkaution',
        'Kautionsvereinbarung',
        'Kautionsbetrag',
        'Kautionsabrechnung',
        'Kautionsrückzahlung',
      ],
      supportingKeywords: [
        'Mieter',
        'Vermieter',
        'Sicherheitsleistung',
        'Kautionskonto',
      ],
      negativeKeywords: ['Kontostand', 'Valuta', 'Buchungstag', 'Inkasso'],
      nextStepKeys: [
        'cat_kaution_step1',
        'cat_kaution_step2',
        'cat_kaution_step3',
        'cat_kaution_step4',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // VERSICHERUNG (General)
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'versicherung_schein',
      labelKey: 'cat_versicherung_schein_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: [
        'Versicherungsschein',
        'Versicherungsnummer',
        'Versicherungsnehmer',
        'Versicherungsbeginn',
      ],
      supportingKeywords: [
        'Versicherungsvertrag',
        'Police',
        'Versicherungssumme',
      ],
      negativeKeywords: [
        'Rechnung',
        'Mahnung',
        'Inkasso',
        'Kontoauszug',
        'Mitgliedsbescheinigung',
      ],
      nextStepKeys: [
        'cat_versicherung_schein_step1',
        'cat_versicherung_schein_step2',
        'cat_versicherung_schein_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'versicherung_beitrag',
      labelKey: 'cat_versicherung_beitrag_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: [
        'Beitragsrechnung',
        'Jahresbeitrag',
        'Versicherungsart',
      ],
      supportingKeywords: [
        'Fälligkeit',
        'Beitrag',
        'fristgerecht',
        'Versicherung',
      ],
      negativeKeywords: ['Rechnungsnummer', 'MwSt', 'Buchungstag', 'Mahnung'],
      nextStepKeys: [
        'cat_versicherung_beitrag_step1',
        'cat_versicherung_beitrag_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'versicherung_schaden_meldung',
      labelKey: 'cat_versicherung_schaden_meldung_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: [
        'Schadenmeldung',
        'Schadennummer',
        'Eingang Ihrer Schadenmeldung',
      ],
      supportingKeywords: ['Schadenfall', 'Prüfung', 'Bearbeitung'],
      negativeKeywords: ['Rechnung', 'Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_versicherung_schaden_meldung_step1',
        'cat_versicherung_schaden_meldung_step2',
        'cat_versicherung_schaden_meldung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'versicherung_schaden_ablehnung',
      labelKey: 'cat_versicherung_schaden_ablehnung_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: ['Ablehnung', 'keine Leistung', 'Versicherungsschutz'],
      supportingKeywords: ['Schadenfall', 'Grund', 'Prüfung'],
      negativeKeywords: ['Rechnung', 'Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_versicherung_schaden_ablehnung_step1',
        'cat_versicherung_schaden_ablehnung_step2',
        'cat_versicherung_schaden_ablehnung_step3',
        'cat_versicherung_schaden_ablehnung_step4',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'versicherung_kuendigung',
      labelKey: 'cat_versicherung_kuendigung_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: [
        'Kündigungsbestätigung',
        'Eingang Ihrer Kündigung',
        'Vertrag endet',
      ],
      supportingKeywords: ['Versicherung', 'Kündigung', 'Vertragsende'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_versicherung_kuendigung_step1',
        'cat_versicherung_kuendigung_step2',
        'cat_versicherung_kuendigung_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // KFZ
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'kfz_evb',
      labelKey: 'cat_kfz_evb_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: [
        'eVB',
        'Elektronische Versicherungsbestätigung',
        'eVB-Nummer',
        'Zulassung',
      ],
      supportingKeywords: ['Fahrzeugzulassung', 'Zulassungsstelle'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: ['cat_kfz_evb_step1', 'cat_kfz_evb_step2'],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'kfz_schaden',
      labelKey: 'cat_kfz_schaden_label',
      mainCategory: MainCategory.categoryInsurance,
      decisiveKeywords: ['Kfz-Schaden', 'Schadennummer Kfz', 'Kfz-Schadenfall'],
      supportingKeywords: ['Schadenmeldung', 'Fahrzeug', 'Unfall'],
      negativeKeywords: ['Rechnung', 'Mahnung'],
      nextStepKeys: [
        'cat_kfz_schaden_step1',
        'cat_kfz_schaden_step2',
        'cat_kfz_schaden_step3',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // VERTRÄGE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'vertrag_kuendigung',
      labelKey: 'cat_vertrag_kuendigung_label',
      mainCategory: MainCategory.categoryContracts,
      decisiveKeywords: [
        'Kündigung',
        'Vertragsverhältnis endet',
        'Vertragsende',
        'gekündigt',
      ],
      supportingKeywords: [
        'Vertrag',
        'Beendigung',
        'endet am',
        'Vertragsnummer',
      ],
      negativeKeywords: ['Mahnung', 'Inkasso', 'Rechnung', 'offener Betrag'],
      nextStepKeys: [
        'cat_vertrag_kuendigung_step1',
        'cat_vertrag_kuendigung_step2',
        'cat_vertrag_kuendigung_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'vertrag_verlaengerung',
      labelKey: 'cat_vertrag_verlaengerung_label',
      mainCategory: MainCategory.categoryContracts,
      decisiveKeywords: [
        'Vertragsverlängerung',
        'verlängert sich automatisch',
        'Verlängerung des Vertrags',
      ],
      supportingKeywords: ['Laufzeit', 'automatisch', 'Vertrag'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepKeys: [
        'cat_vertrag_verlaengerung_step1',
        'cat_vertrag_verlaengerung_step2',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'arbeitsvertrag',
      labelKey: 'cat_arbeitsvertrag_label',
      mainCategory: MainCategory.categoryContracts,
      decisiveKeywords: [
        'Arbeitsvertrag',
        'Arbeitsverhältnis beginnt',
        'Bruttogehalt',
        'Probezeit',
      ],
      supportingKeywords: [
        'Arbeitgeber',
        'Arbeitnehmer',
        'Tätigkeit',
        'Arbeitszeit',
        'Urlaub',
      ],
      negativeKeywords: ['Mahnung', 'Inkasso', 'Mindestlaufzeit'],
      nextStepKeys: [
        'cat_arbeitsvertrag_step1',
        'cat_arbeitsvertrag_step2',
        'cat_arbeitsvertrag_step3',
      ],
      riskLevel: RiskLevel.low,
    ),
  ];
}
