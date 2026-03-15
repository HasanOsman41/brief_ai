/// BriefAI – Category Definitions
///
/// 67 document categories across 10 groups.
/// Jobcenter section updated from BriefAI_Jobcenter_Schluesselwoerter_ohne_Konflikte.docx
/// Each category contains:
///   - decisiveKeywords  : one match → confident classification
///   - supportingKeywords: 2+ matches needed when no decisive keyword found
///   - negativeKeywords  : any match → category disqualified (prevents conflicts)
///   - nextStepsDe / nextStepsAr : constant action steps shown to the user

import '../models/category_definition.dart';
import '../models/document_result.dart';

class BriefAiCategories {
  BriefAiCategories._();

  static const List<CategoryDefinition> all = [
    // ─────────────────────────────────────────────────────────────────────
    // JOBCENTER  (22 categories – updated from dataset file)
    // ─────────────────────────────────────────────────────────────────────

    // ── Core forms ────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_termin',
      labelDe: 'Jobcenter – Einladung zum Termin',
      labelAr: 'مركز التوظيف – دعوة لموعد',
      decisiveKeywords: [
        'Einladung zum Termin',
        'bitte erscheinen Sie',
        'Termin wahrnehmen',
      ],
      supportingKeywords: ['Jobcenter', 'Termin', 'Personalausweis', 'Uhrzeit'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid', 'Steuerbescheid'],
      nextStepsDe: [
        'Termin im Kalender eintragen.',
        'Personalausweis und geforderte Unterlagen vorbereiten.',
        'Pünktlich zum Termin erscheinen.',
        'Bei Verhinderung das Jobcenter vorab informieren.',
      ],
      nextStepsAr: [
        'سجّل الموعد في التقويم.',
        'حضّر بطاقة الهوية والأوراق المطلوبة.',
        'احضر في الوقت المحدد.',
        'إذا لم تستطع الحضور، أخبر مركز التوظيف مسبقًا.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_mitwirkung',
      labelDe: 'Jobcenter – Aufforderung zur Mitwirkung',
      labelAr: 'مركز التوظيف – طلب تقديم مستندات',
      decisiveKeywords: [
        'Aufforderung zur Mitwirkung',
        'Mitwirkungspflicht',
        'fristgerecht eingehen',
      ],
      supportingKeywords: ['Jobcenter', 'Unterlagen', 'Nachweis', 'einreichen'],
      negativeKeywords: ['Inkasso', 'Steuerbescheid'],
      nextStepsDe: [
        'Geforderte Unterlagen zusammenstellen.',
        'Kopien anfertigen.',
        'Vor der genannten Frist beim Jobcenter einreichen.',
        'Einreichungsnachweis aufbewahren.',
      ],
      nextStepsAr: [
        'جهّز المستندات المطلوبة.',
        'صوّر نسخًا منها.',
        'أرسلها قبل الموعد النهائي المذكور.',
        'احتفظ بإثبات الإرسال.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'jobcenter_hauptantrag',
      labelDe: 'Jobcenter – Hauptantrag Bürgergeld (HA)',
      labelAr: 'مركز التوظيف – الطلب الرئيسي للبوريغيلد',
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
      nextStepsDe: [
        'Antrag vollständig ausfüllen.',
        'Alle Pflichtanlagen beifügen (EK, KDU, WEP falls nötig).',
        'Beim Jobcenter einreichen oder online absenden.',
        'Eingangsbestätigung aufbewahren.',
      ],
      nextStepsAr: [
        'أكمل الطلب بالكامل.',
        'أرفق الملحقات الضرورية (EK وKDU وWEP إذا لزم).',
        'سلّمه لمركز التوظيف أو أرسله إلكترونيًا.',
        'احتفظ بتأكيد الاستلام.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_weiterbewilligung',
      labelDe: 'Jobcenter – Weiterbewilligungsantrag (WBA)',
      labelAr: 'مركز التوظيف – طلب تجديد البوريغيلد',
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
      nextStepsDe: [
        'WBA rechtzeitig vor Ablauf des Bewilligungszeitraums einreichen.',
        'Änderungen in Einkommen oder Wohnsituation angeben.',
        'Alle aktuellen Nachweise beilegen.',
      ],
      nextStepsAr: [
        'قدّم طلب التجديد قبل انتهاء فترة الاستحقاق.',
        'اذكر أي تغييرات في الدخل أو السكن.',
        'أرفق كل الإثباتات الحالية.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_veraenderung',
      labelDe: 'Jobcenter – Veränderungsmitteilung (VÄM)',
      labelAr: 'مركز التوظيف – إشعار بتغيير',
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
      nextStepsDe: [
        'Änderung unverzüglich beim Jobcenter melden.',
        'Nachweise zur Änderung einreichen.',
        'Rückmeldung des Jobcenters abwarten.',
      ],
      nextStepsAr: [
        'أبلغ مركز التوظيف فورًا بالتغيير.',
        'قدّم الإثباتات المتعلقة بالتغيير.',
        'انتظر الرد من مركز التوظيف.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_ausfuellhinweise',
      labelDe: 'Jobcenter – Ausfüllhinweise (AH)',
      labelAr: 'مركز التوظيف – تعليمات التعبئة',
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
      nextStepsDe: [
        'Hinweise sorgfältig lesen, bevor Sie den Antrag ausfüllen.',
        'Bei Unklarheiten das Jobcenter kontaktieren.',
      ],
      nextStepsAr: [
        'اقرأ التعليمات بعناية قبل تعبئة الطلب.',
        'تواصل مع مركز التوظيف عند الشك.',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ── Anlagen (Attachments) ─────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_anlage_wep',
      labelDe: 'Jobcenter – Anlage WEP (weitere Person ab 15 Jahren)',
      labelAr: 'مركز التوظيف – ملحق WEP (شخص إضافي 15+ سنة)',
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
      nextStepsDe: [
        'Anlage WEP für jede weitere Person ab 15 Jahren ausfüllen.',
        'Zusammen mit dem Hauptantrag einreichen.',
      ],
      nextStepsAr: [
        'أكمل ملحق WEP لكل شخص إضافي عمره 15 سنة أو أكثر.',
        'أرسله مع الطلب الرئيسي.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ki',
      labelDe: 'Jobcenter – Anlage KI (Kinder unter 15 Jahren)',
      labelAr: 'مركز التوظيف – ملحق KI (أطفال دون 15 سنة)',
      decisiveKeywords: ['Anlage KI', 'Kind unter 15 Jahren'],
      supportingKeywords: [
        'Kindergeld',
        'Unterhaltsvorschuss',
        'Schülerin',
        'Schüler',
      ],
      negativeKeywords: ['Kindesunterhalt', 'Anlage WEP', 'Inkasso'],
      nextStepsDe: [
        'Anlage KI für jedes Kind unter 15 Jahren ausfüllen.',
        'Kindergeld- und Unterhaltsangaben bereithalten.',
      ],
      nextStepsAr: [
        'أكمل ملحق KI لكل طفل عمره أقل من 15 سنة.',
        'جهّز معلومات الكيندرغيلد والنفقة.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_hg',
      labelDe: 'Jobcenter – Anlage HG (Haushaltsgemeinschaft)',
      labelAr: 'مركز التوظيف – ملحق HG (السكن مع أقارب)',
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
      nextStepsDe: [
        'Anlage HG ausfüllen wenn Sie mit Verwandten zusammenwohnen.',
        'Angaben zur finanziellen Unterstützung wahrheitsgemäß machen.',
      ],
      nextStepsAr: [
        'أكمل ملحق HG إذا كنت تسكن مع أقارب.',
        'اذكر معلومات الدعم المالي بصدق.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ve',
      labelDe:
          'Jobcenter – Anlage VE (Verantwortungs- und Einstehensgemeinschaft)',
      labelAr: 'مركز التوظيف – ملحق VE (الشراكة المعيشية)',
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
      nextStepsDe: [
        'Anlage VE ausfüllen wenn Sie mit einem Partner zusammenleben.',
        'Alle gemeinsamen finanziellen Verhältnisse angeben.',
      ],
      nextStepsAr: [
        'أكمل ملحق VE إذا كنت تعيش مع شريك/ة.',
        'اذكر كل الأوضاع المالية المشتركة.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_ek',
      labelDe: 'Jobcenter – Anlage EK (Einkommen)',
      labelAr: 'مركز التوظيف – ملحق EK (الدخل)',
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
      nextStepsDe: [
        'Anlage EK für jede Person mit Einkommen in der Bedarfsgemeinschaft ausfüllen.',
        'Gehaltsabrechnungen der letzten Monate beilegen.',
      ],
      nextStepsAr: [
        'أكمل ملحق EK لكل شخص لديه دخل في مجموعة الاحتياج.',
        'أرفق كشوف الراتب للأشهر الأخيرة.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_vm',
      labelDe: 'Jobcenter – Anlage VM (Vermögen)',
      labelAr: 'مركز التوظيف – ملحق VM (الأصول والثروة)',
      decisiveKeywords: ['Anlage VM', 'Selbstauskunft über das Vermögen'],
      supportingKeywords: [
        'Vermögensverhältnisse',
        'Geldanlagen',
        'Kryptowährungen',
        'Schmuck',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepsDe: [
        'Alle Vermögenswerte vollständig und wahrheitsgemäß angeben.',
        'Kontoauszüge und Nachweise über Geldanlagen beilegen.',
      ],
      nextStepsAr: [
        'اذكر جميع الأصول بشكل كامل وصادق.',
        'أرفق كشوف الحساب وإثباتات الاستثمارات.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_kdu',
      labelDe: 'Jobcenter – Anlage KDU (Kosten der Unterkunft und Heizung)',
      labelAr: 'مركز التوظيف – ملحق KDU (تكاليف السكن والتدفئة)',
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
      nextStepsDe: [
        'Mietvertrag und aktuelle Nebenkostenabrechnungen bereithalten.',
        'Alle Wohn- und Heizkosten vollständig eintragen.',
      ],
      nextStepsAr: [
        'جهّز عقد الإيجار وكشوف التكاليف الإضافية الحالية.',
        'أدخل كل تكاليف السكن والتدفئة بالكامل.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_eks',
      labelDe: 'Jobcenter – Anlage EKS (Selbständige Tätigkeit)',
      labelAr: 'مركز التوظيف – ملحق EKS (دخل العمل الحر)',
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
      nextStepsDe: [
        'EKS für selbständige oder freiberufliche Tätigkeit ausfüllen.',
        'Einnahmen und Betriebsausgaben detailliert angeben.',
        'Nicht mit Anlage EK (Arbeitnehmer) verwechseln.',
      ],
      nextStepsAr: [
        'أكمل EKS للعمل الحر أو المستقل.',
        'اذكر الإيرادات والمصاريف بالتفصيل.',
        'لا تخلطه مع ملحق EK (الموظفين).',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_meb',
      labelDe: 'Jobcenter – Anlage MEB (Mehrbedarf Ernährung)',
      labelAr: 'مركز التوظيف – ملحق MEB (احتياج غذائي إضافي)',
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
      nextStepsDe: [
        'Ärztliche Bescheinigung über die notwendige Ernährungsform beilegen.',
        'Anlage MEB zusammen mit dem Antrag einreichen.',
      ],
      nextStepsAr: [
        'أرفق شهادة طبية تثبت النظام الغذائي الضروري.',
        'أرسل ملحق MEB مع الطلب.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_sv',
      labelDe: 'Jobcenter – Anlage SV (Kranken- und Sozialversicherung)',
      labelAr: 'مركز التوظيف – ملحق SV (التأمين الصحي والاجتماعي)',
      decisiveKeywords: ['Anlage SV'],
      supportingKeywords: [
        'Kranken- und Pflegeversicherung',
        'privat krankenversichert',
        'Basistarif',
        'Zuschuss zu den Beiträgen',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepsDe: [
        'Anlage SV ausfüllen wenn Sie privat krankenversichert sind.',
        'Nachweis über Versicherung und Beitragshöhe beilegen.',
      ],
      nextStepsAr: [
        'أكمل ملحق SV إذا كنت مؤمّنًا صحيًا بشكل خاص.',
        'أرفق إثبات التأمين وقيمة الاشتراك.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_bb',
      labelDe: 'Jobcenter – Anlage BB (Besonderer Bedarf)',
      labelAr: 'مركز التوظيف – ملحق BB (احتياج خاص لا يمكن تأجيله)',
      decisiveKeywords: ['Anlage BB', 'unabweisbarer besonderer Bedarf'],
      supportingKeywords: ['Kostenvoranschlag', 'Vorschuss', 'Quittungen'],
      negativeKeywords: ['Inkasso'],
      nextStepsDe: [
        'Unabweisbaren Bedarf konkret begründen.',
        'Kostenvoranschlag oder Quittungen beilegen.',
      ],
      nextStepsAr: [
        'اشرح الاحتياج الضروري بشكل محدد.',
        'أرفق عرض تكلفة أو إيصالات.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uf',
      labelDe: 'Jobcenter – Anlage UF (Unfall / Schaden durch Dritte)',
      labelAr: 'مركز التوظيف – ملحق UF (حادث أو ضرر من طرف ثالث)',
      decisiveKeywords: ['Anlage UF', 'Schadensereignis'],
      supportingKeywords: [
        'Unfallbericht',
        'Haftpflichtversicherung',
        'Schadensnummer',
      ],
      negativeKeywords: ['Inkasso'],
      nextStepsDe: [
        'Anlage UF ausfüllen wenn ein Unfall oder Schaden durch Dritte vorliegt.',
        'Unfallbericht und alle Belege beilegen.',
      ],
      nextStepsAr: [
        'أكمل ملحق UF في حالة وقوع حادث أو ضرر من طرف ثالث.',
        'أرفق تقرير الحادث وكل الإثباتات.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ── Unterhalt (Maintenance) ────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_anlage_uh1',
      labelDe:
          'Jobcenter – Anlage UH1 (Trennungsunterhalt / nachehelicher Unterhalt)',
      labelAr: 'مركز التوظيف – ملحق UH1 (نفقة الانفصال أو ما بعد الطلاق)',
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
      nextStepsDe: [
        'Anlage UH1 bei Trennungs- oder nachehelichem Unterhalt ausfüllen.',
        'Gerichtliche Vereinbarungen oder Urteile beilegen.',
      ],
      nextStepsAr: [
        'أكمل ملحق UH1 في حالة نفقة الانفصال أو ما بعد الطلاق.',
        'أرفق الاتفاقيات القضائية أو الأحكام.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uh2',
      labelDe: 'Jobcenter – Anlage UH2 (Unterhalt wegen Schwangerschaft)',
      labelAr: 'مركز التوظيف – ملحق UH2 (نفقة الحمل)',
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
      nextStepsDe: [
        'Anlage UH2 bei Schwangerschaft und Unterhaltsansprüchen ausfüllen.',
        'Angaben zum voraussichtlichen Geburtstermin machen.',
      ],
      nextStepsAr: [
        'أكمل ملحق UH2 عند وجود نفقة مرتبطة بالحمل.',
        'اذكر الموعد المتوقع للولادة.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'jobcenter_anlage_uh3',
      labelDe: 'Jobcenter – Anlage UH3 (Kindesunterhalt)',
      labelAr: 'مركز التوظيف – ملحق UH3 (نفقة الأطفال)',
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
      nextStepsDe: [
        'Anlage UH3 ausfüllen wenn ein Elternteil außerhalb der Bedarfsgemeinschaft lebt.',
        'Unterhaltstitel oder Vereinbarungen beilegen.',
      ],
      nextStepsAr: [
        'أكمل ملحق UH3 إذا كان أحد الوالدين خارج مجموعة الاحتياج.',
        'أرفق سند النفقة أو الاتفاقيات.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ── Employer-issued forms ─────────────────────────────────────────────
    CategoryDefinition(
      id: 'jobcenter_einkommensbescheinigung',
      labelDe: 'Jobcenter – Einkommensbescheinigung (vom Arbeitgeber)',
      labelAr: 'مركز التوظيف – شهادة الدخل من صاحب العمل',
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
      nextStepsDe: [
        'Formular dem Arbeitgeber zur Ausfüllung vorlegen.',
        'Ausgefüllte Bescheinigung beim Jobcenter einreichen.',
      ],
      nextStepsAr: [
        'قدّم النموذج لصاحب العمل لتعبئته.',
        'أرسل الشهادة المكتملة إلى مركز التوظيف.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_arbeitsbescheinigung',
      labelDe: 'Jobcenter – Arbeitsbescheinigung SGB II',
      labelAr: 'مركز التوظيف – شهادة العمل SGB II',
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
      nextStepsDe: [
        'Formular dem Arbeitgeber zur Ausfüllung vorlegen.',
        'Sicherstellen dass SGB II auf dem Formular steht.',
        'Ausgefüllte Bescheinigung beim Jobcenter einreichen.',
      ],
      nextStepsAr: [
        'قدّم النموذج لصاحب العمل لتعبئته.',
        'تأكد من ظهور SGB II على النموذج.',
        'أرسل الشهادة المكتملة إلى مركز التوظيف.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'jobcenter_mietbescheinigung',
      labelDe: 'Jobcenter – Mietbescheinigung / Vermieterbescheinigung',
      labelAr: 'مركز التوظيف – شهادة السكن من المالك',
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
      nextStepsDe: [
        'Formular dem Vermieter zur Ausfüllung vorlegen.',
        'Ausgefüllte Bescheinigung beim Jobcenter einreichen.',
        'Nicht mit Anlage KDU verwechseln.',
      ],
      nextStepsAr: [
        'قدّم النموذج للمالك لتعبئته.',
        'أرسل الشهادة المكتملة إلى مركز التوظيف.',
        'لا تخلطه مع ملحق KDU.',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // AUSLÄNDERBEHÖRDE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'auslaender_termin',
      labelDe: 'Ausländerbehörde – Terminbestätigung / Einladung',
      labelAr: 'دائرة الأجانب – تأكيد موعد أو دعوة للحضور',
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
      nextStepsDe: [
        'Termin im Kalender speichern.',
        'Alle geforderten Unterlagen vorbereiten (Pass, Foto, Aufenthaltstitel).',
        'Pünktlich erscheinen.',
        'Bei Verhinderung Termin vorab absagen oder verlegen.',
      ],
      nextStepsAr: [
        'سجّل الموعد في التقويم.',
        'جهّز الأوراق المطلوبة (جواز، صورة، بطاقة إقامة).',
        'احضر في الوقت المحدد.',
        'إذا تعذّر الحضور، ألغِ أو أعد الجدولة مسبقًا.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_unterlagen',
      labelDe: 'Ausländerbehörde – Aufforderung zur Vorlage von Unterlagen',
      labelAr: 'دائرة الأجانب – طلب تقديم مستندات',
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
      nextStepsDe: [
        'Deadline aus der Frist entnehmen.',
        'Alle genannten Dokumente zusammenstellen.',
        'Fristgerecht einreichen oder hochladen.',
        'Eingangsbestätigung aufbewahren.',
      ],
      nextStepsAr: [
        'استخرج الموعد النهائي من المهلة المذكورة.',
        'اجمع كل المستندات المذكورة.',
        'أرسلها أو ارفعها قبل انتهاء المهلة.',
        'احتفظ بتأكيد الاستلام.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_verlaengerung',
      labelDe: 'Ausländerbehörde – Verlängerung des Aufenthaltstitels',
      labelAr: 'دائرة الأجانب – تمديد الإقامة',
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
      nextStepsDe: [
        'Verlängerungsantrag rechtzeitig vor Ablauf stellen.',
        'Aktuelle Unterlagen (Pass, Foto, Nachweise) vorbereiten.',
        'Termin bei der Ausländerbehörde buchen.',
        'Fiktionsbescheinigung anfragen, falls Titel bereits abläuft.',
      ],
      nextStepsAr: [
        'قدّم طلب التمديد قبل انتهاء صلاحية الإقامة.',
        'جهّز الأوراق الحالية (جواز، صورة، إثباتات).',
        'احجز موعدًا في دائرة الأجانب.',
        'اطلب شهادة الاستمرار المؤقت إذا كانت الإقامة على وشك الانتهاء.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'auslaender_bewilligung',
      labelDe: 'Ausländerbehörde – Bewilligungsbescheid (Zustimmung)',
      labelAr: 'دائرة الأجانب – موافقة على الإقامة',
      decisiveKeywords: [
        'stattgegeben',
        'wird erteilt',
        'Bewilligungsbescheid',
      ],
      supportingKeywords: ['Aufenthaltserlaubnis', 'genehmigt', 'Erteilung'],
      negativeKeywords: ['abgelehnt', 'wird nicht erteilt', 'Inkasso'],
      nextStepsDe: [
        'Bescheid sorgfältig lesen und Auflagen notieren.',
        'Neuen Aufenthaltstitel abholen (Termin beachten).',
        'Dokument sicher aufbewahren.',
      ],
      nextStepsAr: [
        'اقرأ القرار بعناية وسجّل أي شروط.',
        'استلم بطاقة الإقامة الجديدة (لاحظ موعد الاستلام).',
        'احفظ الوثيقة في مكان آمن.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'auslaender_ablehnung',
      labelDe: 'Ausländerbehörde – Ablehnungsbescheid',
      labelAr: 'دائرة الأجانب – رفض طلب الإقامة',
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
      nextStepsDe: [
        'Ablehnungsgrund genau lesen.',
        'Innerhalb der Rechtsbehelfsfrist Widerspruch prüfen (1 Monat).',
        'Rechtsberatung oder Migrationsberatung aufsuchen.',
        'Fehlende Unterlagen nachreichen, falls möglich.',
      ],
      nextStepsAr: [
        'اقرأ سبب الرفض بعناية.',
        'ادرس تقديم اعتراض خلال مهلة الطعن (عادةً شهر واحد).',
        'استشر محاميًا أو مستشار هجرة.',
        'أكمل المستندات الناقصة إذا أمكن.',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'auslaender_fiktionsbescheinigung',
      labelDe: 'Ausländerbehörde – Fiktionsbescheinigung',
      labelAr: 'دائرة الأجانب – تأكيد استمرار الإقامة مؤقتًا',
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
      nextStepsDe: [
        'Bescheinigung als aktuellen Aufenthaltsnachweis nutzen.',
        'Auf Entscheidung der Behörde warten.',
        'Eventuelle Nachforderungen fristgerecht erfüllen.',
      ],
      nextStepsAr: [
        'استخدم الشهادة كإثبات إقامة حالي.',
        'انتظر قرار الجهة الرسمية.',
        'أكمل أي طلبات إضافية في الوقت المحدد.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'auslaender_abholung_eat',
      labelDe: 'Ausländerbehörde – Abholung des eAT',
      labelAr: 'دائرة الأجانب – استلام بطاقة الإقامة الإلكترونية',
      decisiveKeywords: [
        'liegt zur Abholung bereit',
        'elektronischer Aufenthaltstitel',
        'Dokumentenausgabebox',
      ],
      supportingKeywords: ['eAT', 'Abholung', 'Reisepass mitbringen'],
      negativeKeywords: ['Termin', 'Inkasso'],
      nextStepsDe: [
        'Ausweis / Pass zur Abholung mitbringen.',
        'eAT im angegebenen Zeitraum abholen.',
        'Daten auf dem eAT nach Erhalt überprüfen.',
      ],
      nextStepsAr: [
        'أحضر الهوية أو الجواز لاستلام البطاقة.',
        'استلم البطاقة خلال الفترة المحددة.',
        'تحقق من بيانات البطاقة بعد الاستلام.',
      ],
      riskLevel: RiskLevel.low,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // KRANKENKASSE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'krankenkasse_bescheinigung',
      labelDe: 'Krankenkasse – Versicherungsbescheinigung',
      labelAr: 'التأمين الصحي – شهادة التأمين أو العضوية',
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
      nextStepsDe: [
        'Bescheinigung speichern – wird für Behörden, Arbeitgeber oder Ausländerbehörde benötigt.',
        'Bei Ausländerbehörde als Nachweis der Krankenversicherung vorlegen.',
      ],
      nextStepsAr: [
        'احفظ الشهادة – ستحتاجها للجهات الرسمية أو صاحب العمل أو دائرة الأجانب.',
        'قدّمها كإثبات تأمين صحي عند دائرة الأجانب.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'krankenkasse_beitrag',
      labelDe: 'Krankenkasse – Beitragsbescheid',
      labelAr: 'التأمين الصحي – إشعار الاشتراك',
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
      nextStepsDe: [
        'Beitragshöhe und Fälligkeitsdatum prüfen.',
        'Beitrag rechtzeitig überweisen.',
        'Bei Änderungen des Einkommens ggf. Ermäßigung beantragen.',
      ],
      nextStepsAr: [
        'راجع قيمة الاشتراك وتاريخ الاستحقاق.',
        'ادفع الاشتراك في الوقت المحدد.',
        'إذا تغيّر دخلك، فكّر في طلب تخفيض الاشتراك.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'krankenkasse_mahnung',
      labelDe: 'Krankenkasse – Mahnung / Beitragsrückstand',
      labelAr: 'التأمين الصحي – إنذار أو تأخر بالدفع',
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
      nextStepsDe: [
        'Offenen Beitrag sofort begleichen.',
        'Bei finanziellen Schwierigkeiten Ratenzahlung mit der Krankenkasse vereinbaren.',
        'Nicht ignorieren – Rückstände können zu Leistungskürzungen führen.',
      ],
      nextStepsAr: [
        'ادفع الاشتراك المتأخر فورًا.',
        'إذا كنت في صعوبة مالية، اتفق على دفع بالتقسيط مع شركة التأمين.',
        'لا تتجاهل الأمر – التأخيرات قد تؤثر على التغطية التأمينية.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'krankenkasse_krankengeld',
      labelDe: 'Krankenkasse – Krankengeld',
      labelAr: 'التأمين الصحي – تعويض المرض',
      decisiveKeywords: [
        'Krankengeld',
        'Arbeitsunfähigkeit',
        'Arbeitsunfähigkeitsbescheinigung',
      ],
      supportingKeywords: ['Krankenkasse', 'AU', 'krank', 'Lohnfortzahlung'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Arbeitsunfähigkeitsbescheinigung (AU) rechtzeitig einreichen.',
        'Zeitraum und Höhe des Krankengeldes prüfen.',
        'Arbeitgeber und Jobcenter (falls Bürgergeld) informieren.',
      ],
      nextStepsAr: [
        'أرسل شهادة العجز عن العمل في الوقت المحدد.',
        'راجع مدة وقيمة تعويض المرض.',
        'أبلغ صاحب العمل ومركز التوظيف (إذا كنت تتلقى بوريغيلد).',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'krankenkasse_kuendigung',
      labelDe: 'Krankenkasse – Kündigung / Kassenwechsel',
      labelAr: 'التأمين الصحي – إلغاء أو تغيير التأمين',
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
      nextStepsDe: [
        'Neue Krankenkasse rechtzeitig auswählen und anmelden.',
        'Sicherstellen, dass keine Versicherungslücke entsteht.',
        'Arbeitgeber über Wechsel informieren.',
      ],
      nextStepsAr: [
        'اختر شركة تأمين صحي جديدة وسجّل فيها مسبقًا.',
        'تأكد من عدم وجود فجوة في التغطية التأمينية.',
        'أبلغ صاحب العمل بالتغيير.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // FINANZAMT
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'finanzamt_steuerbescheid',
      labelDe: 'Finanzamt – Steuerbescheid (Nachzahlung)',
      labelAr: 'مكتب الضرائب – قرار ضريبي (مطالبة بالدفع)',
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
      nextStepsDe: [
        'Bescheid prüfen – Frist für Einspruch beachten (1 Monat).',
        'Nachzahlungsbetrag bis zum genannten Datum überweisen.',
        'Bei Unklarheiten Steuerberater konsultieren.',
      ],
      nextStepsAr: [
        'راجع القرار – لاحظ مهلة الاعتراض (شهر واحد).',
        'ادفع المبلغ المطلوب قبل التاريخ المذكور.',
        'استشر مستشارًا ضريبيًا عند الشك.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'finanzamt_erstattung',
      labelDe: 'Finanzamt – Steuererstattung',
      labelAr: 'مكتب الضرائب – استرداد ضريبي',
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
      nextStepsDe: [
        'Kein dringender Handlungsbedarf.',
        'Erstattungsbetrag und Bankverbindung im Bescheid prüfen.',
        'Rückzahlung abwarten.',
      ],
      nextStepsAr: [
        'لا يلزم إجراء عاجل.',
        'راجع مبلغ الاسترداد وبيانات الحساب في القرار.',
        'انتظر تحويل المبلغ.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'finanzamt_abgabe',
      labelDe: 'Finanzamt – Aufforderung zur Abgabe der Steuererklärung',
      labelAr: 'مكتب الضرائب – طلب تقديم الإقرار الضريبي',
      decisiveKeywords: [
        'Abgabe der Steuererklärung',
        'Aufforderung Steuererklärung',
      ],
      supportingKeywords: ['Finanzamt', 'Frist', 'Steuerjahr', 'einreichen'],
      negativeKeywords: ['Inkasso', 'Mahnung'],
      nextStepsDe: [
        'Steuererklärung für das angegebene Jahr vorbereiten.',
        'Frist einhalten (meist 31.07. des Folgejahres).',
        'Bei Bedarf Fristverlängerung beantragen oder Steuerberater hinzuziehen.',
      ],
      nextStepsAr: [
        'جهّز الإقرار الضريبي للسنة المذكورة.',
        'الزم الموعد النهائي (عادةً 31.07 من السنة التالية).',
        'اطلب تمديدًا أو استعن بمستشار ضريبي عند الحاجة.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'finanzamt_verspaetung',
      labelDe: 'Finanzamt – Verspätungszuschlag',
      labelAr: 'مكتب الضرائب – غرامة تأخير',
      decisiveKeywords: ['Verspätungszuschlag', 'verspätet eingereicht'],
      supportingKeywords: ['Finanzamt', 'Zuschlag', 'Steuererklärung'],
      negativeKeywords: ['Inkasso'],
      nextStepsDe: [
        'Zuschlagsbescheid prüfen.',
        'Betrag fristgerecht bezahlen.',
        'Künftig Steuererklärung pünktlich abgeben.',
      ],
      nextStepsAr: [
        'راجع قرار الغرامة.',
        'ادفع المبلغ في الوقت المحدد.',
        'قدّم الإقرار الضريبي في المستقبل في وقته.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // BANK
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'bank_kontoauszug',
      labelDe: 'Bank – Kontoauszug',
      labelAr: 'البنك – كشف حساب',
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
      nextStepsDe: [
        'Kontobewegungen sorgfältig prüfen.',
        'Unbekannte Abbuchungen sofort der Bank melden.',
        'Kontoauszug für Steuererklärung oder Behörden aufbewahren.',
      ],
      nextStepsAr: [
        'راجع حركات الحساب بعناية.',
        'أبلغ البنك فورًا عن أي خصم غير معروف.',
        'احتفظ بكشف الحساب للإقرار الضريبي أو الجهات الرسمية.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'bank_sicherheitswarnung',
      labelDe: 'Bank – Sicherheitswarnung',
      labelAr: 'البنك – تحذير أمني',
      decisiveKeywords: [
        'Sicherheitswarnung',
        'ungewöhnliche Aktivität',
        'Kontosicherheit',
      ],
      supportingKeywords: ['Konto', 'verdächtig', 'Überprüfung', 'Bank'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepsDe: [
        'Konto sofort prüfen.',
        'Direkt die Bank kontaktieren (nur über offizielle Nummer).',
        'Online-Banking-Passwort ändern.',
        'Keine Links in der E-Mail anklicken – könnte Phishing sein.',
      ],
      nextStepsAr: [
        'افحص حسابك فورًا.',
        'تواصل مع البنك مباشرةً (عبر الرقم الرسمي فقط).',
        'غيّر كلمة مرور الخدمات المصرفية.',
        'لا تنقر على أي رابط في الرسالة – قد يكون احتيالًا.',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'bank_ueberweisung',
      labelDe: 'Bank – Überweisungsbestätigung',
      labelAr: 'البنك – تأكيد تحويل مالي',
      decisiveKeywords: [
        'Überweisung erfolgreich',
        'Überweisungsauftrag',
        'Empfänger',
      ],
      supportingKeywords: ['IBAN', 'Betrag', 'SEPA', 'ausgeführt'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: ['Überweisungsbestätigung für Ihre Unterlagen speichern.'],
      nextStepsAr: ['احفظ تأكيد التحويل للرجوع إليه لاحقًا.'],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'bank_ruecklastschrift',
      labelDe: 'Bank – Rücklastschrift',
      labelAr: 'البنك – فشل السحب المباشر',
      decisiveKeywords: [
        'Rücklastschrift',
        'nicht durchgeführt',
        'Kontodeckung',
      ],
      supportingKeywords: ['Lastschrift', 'Abbuchung', 'Betrag'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepsDe: [
        'Ausreichende Kontodeckung sicherstellen.',
        'Ursache mit der Bank klären.',
        'Zahlungsempfänger informieren, damit kein Mahnverfahren eingeleitet wird.',
      ],
      nextStepsAr: [
        'تأكد من وجود رصيد كافٍ.',
        'تواصل مع البنك لمعرفة السبب.',
        'أبلغ المستلم حتى لا يُفتح إجراء إنذار.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'bank_ueberziehung',
      labelDe: 'Bank – Kontoüberziehung',
      labelAr: 'البنك – تجاوز رصيد الحساب',
      decisiveKeywords: ['Kontoüberziehung', 'negativer Saldo', 'Überziehung'],
      supportingKeywords: ['Konto', 'Saldo', 'ausgleichen'],
      negativeKeywords: ['Rechnung', 'Inkasso'],
      nextStepsDe: [
        'Konto so schnell wie möglich ausgleichen.',
        'Überziehungszinsen (Dispositionszinsen) prüfen.',
        'Bei dauerhafter Überziehung Beratung bei der Bank suchen.',
      ],
      nextStepsAr: [
        'اعمل على تغطية الرصيد السلبي في أقرب وقت.',
        'راجع فوائد السحب على المكشوف.',
        'إذا كان الوضع متكررًا، استشر البنك.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // RECHNUNG / MAHNUNG / INKASSO / GERICHT
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'rechnung',
      labelDe: 'Rechnung',
      labelAr: 'فاتورة',
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
      nextStepsDe: [
        'Rechnung auf Richtigkeit prüfen.',
        'Betrag vor dem Fälligkeitsdatum überweisen.',
        'Rechnung für die Buchhaltung aufbewahren.',
      ],
      nextStepsAr: [
        'تحقق من صحة الفاتورة.',
        'ادفع المبلغ قبل تاريخ الاستحقاق.',
        'احتفظ بالفاتورة للمحاسبة.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'zahlungserinnerung',
      labelDe: 'Zahlungserinnerung',
      labelAr: 'تذكير بالدفع',
      decisiveKeywords: [
        'Zahlungserinnerung',
        'offener Betrag',
        'kein Zahlungseingang',
      ],
      supportingKeywords: ['Rechnung', 'bitte zahlen', 'innerhalb von'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid'],
      nextStepsDe: [
        'Prüfen, ob die Rechnung bereits bezahlt wurde.',
        'Betrag sofort überweisen, falls noch nicht geschehen.',
        'Zahlungsbeleg aufbewahren.',
      ],
      nextStepsAr: [
        'تحقق مما إذا كنت قد دفعت الفاتورة.',
        'ادفع المبلغ فورًا إذا لم يتم الدفع.',
        'احتفظ بإيصال الدفع.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'mahnung',
      labelDe: 'Mahnung',
      labelAr: 'إنذار دفع',
      decisiveKeywords: ['Mahnung', 'offene Forderung', 'Zahlungsfrist'],
      supportingKeywords: ['kein Zahlungseingang', 'Betrag', 'zahlen'],
      negativeKeywords: ['Inkasso', 'Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepsDe: [
        'Sofort prüfen, ob der Betrag korrekt ist.',
        'Zahlung unverzüglich durchführen oder Ratenzahlung vereinbaren.',
        'Nicht ignorieren – weitere Mahnstufen drohen.',
      ],
      nextStepsAr: [
        'تحقق فورًا من صحة المبلغ.',
        'ادفع على الفور أو اتفق على تقسيط.',
        'لا تتجاهل الأمر – قد تأتي مستويات إنذار أشد.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'letzte_mahnung',
      labelDe: 'Letzte Mahnung',
      labelAr: 'الإنذار الأخير',
      decisiveKeywords: ['Letzte Mahnung', 'letzte Frist'],
      supportingKeywords: ['spätestens', 'Inkasso', 'offener Betrag'],
      negativeKeywords: ['Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepsDe: [
        'Betrag sofort bezahlen.',
        'Andernfalls wird das Inkassoverfahren eingeleitet.',
        'Bei bestrittener Forderung sofort schriftlich widersprechen.',
      ],
      nextStepsAr: [
        'ادفع المبلغ فورًا.',
        'وإلا سيُفتح إجراء تحصيل الديون.',
        'إذا كنت تعترض على الدين، قدّم اعتراضًا كتابيًا فورًا.',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'inkasso',
      labelDe: 'Inkasso-Forderung',
      labelAr: 'مطالبة إنكاسو (تحصيل ديون)',
      decisiveKeywords: [
        'Inkasso',
        'Inkassoforderung',
        'Hauptforderung',
        'Inkassokosten',
      ],
      supportingKeywords: ['Gesamtforderung', 'Auftraggeber', 'Inkassobüro'],
      negativeKeywords: ['Mahnbescheid', 'Vollstreckungsbescheid'],
      nextStepsDe: [
        'Forderung auf Richtigkeit und Verjährung prüfen.',
        'Schuldnerberatung aufsuchen, wenn nötig.',
        'Nicht ignorieren – Klage oder Mahnbescheid drohen.',
        'Zahlen oder schriftlich widersprechen.',
      ],
      nextStepsAr: [
        'تحقق من صحة الدين وإذا كان قد تقادم.',
        'استشر مستشار ديون إذا لزم.',
        'لا تتجاهل – قد تأتي دعوى قضائية أو إشعار محكمة.',
        'ادفع أو قدّم اعتراضًا كتابيًا.',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'mahnbescheid',
      labelDe: 'Mahnbescheid (Gericht)',
      labelAr: 'إشعار محكمة بالمطالبة',
      decisiveKeywords: ['Mahnbescheid', 'Widerspruch', 'Gericht'],
      supportingKeywords: ['Hauptforderung', 'Zustellung', 'zwei Wochen'],
      negativeKeywords: ['Vollstreckungsbescheid'],
      nextStepsDe: [
        'DRINGEND: Frist von 2 Wochen für Widerspruch beachten.',
        'Forderung prüfen – ist sie berechtigt?',
        'Widerspruch einlegen, wenn Forderung falsch ist.',
        'Anwalt oder Schuldnerberatung aufsuchen.',
      ],
      nextStepsAr: [
        'عاجل: لاحظ مهلة الاعتراض خلال أسبوعين.',
        'تحقق من الدين – هل هو صحيح؟',
        'قدّم اعتراضًا إذا كان الدين خاطئًا.',
        'استشر محاميًا أو مستشار ديون.',
      ],
      riskLevel: RiskLevel.critical,
    ),
    CategoryDefinition(
      id: 'vollstreckungsbescheid',
      labelDe: 'Vollstreckungsbescheid / Zwangsvollstreckung',
      labelAr: 'أمر تنفيذ / تنفيذ جبري',
      decisiveKeywords: [
        'Vollstreckungsbescheid',
        'Zwangsvollstreckung',
        'Gerichtsvollzieher',
        'Pfändung',
      ],
      supportingKeywords: ['Einspruch', 'vollstreckbar', 'Mahnbescheid'],
      negativeKeywords: [],
      nextStepsDe: [
        'SOFORT handeln – Frist für Einspruch (2 Wochen) beachten.',
        'Rechtsberatung oder Schuldnerberatung aufsuchen.',
        'Möglichkeit prüfen, die Schuld zu begleichen oder Ratenzahlung zu vereinbaren.',
      ],
      nextStepsAr: [
        'تصرف فورًا – لاحظ مهلة الاعتراض (أسبوعان).',
        'استشر محاميًا أو مستشار ديون.',
        'ادرس سداد الدين أو الاتفاق على تقسيط.',
      ],
      riskLevel: RiskLevel.critical,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // WOHNEN / MIETE / KAUTION
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'miete_kuendigung',
      labelDe: 'Kündigung Mietvertrag',
      labelAr: 'إلغاء عقد الإيجار',
      decisiveKeywords: [
        'Kündigung Mietvertrag',
        'kündigen wir den Mietvertrag',
        'fristlose Kündigung',
        'Mietverhältnis kündigen',
        'kündigen wir das Mietverhältnis',
      ],
      supportingKeywords: ['Wohnung', 'Mietende', 'Vermieter', 'Mieter'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Kündigungsdatum und -fristen prüfen.',
        'Neue Unterkunft rechtzeitig suchen.',
        'Wohnungsübergabe und Kautionsrückgabe klären.',
        'Ummeldung nicht vergessen.',
      ],
      nextStepsAr: [
        'راجع تاريخ الإلغاء ومهله.',
        'ابحث عن سكن جديد في الوقت المناسب.',
        'رتّب تسليم الشقة واسترداد الكفالة.',
        'لا تنسَ تغيير عنوانك الرسمي.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'mietvertrag',
      labelDe: 'Mietvertrag',
      labelAr: 'عقد إيجار',
      decisiveKeywords: ['Mietvertrag', 'Kaltmiete', 'Warmmiete', 'Mietbeginn'],
      supportingKeywords: ['Mieter', 'Vermieter', 'Wohnung', 'Nebenkosten'],
      negativeKeywords: [
        'Mahnung',
        'Inkasso',
        'Kontoauszug',
        'Kündigung',
        'kündigen',
      ],
      nextStepsDe: [
        'Alle Vertragsdaten sorgfältig prüfen.',
        'Mietbeginn und Kaution notieren.',
        'Wohnungsübergabeprotokoll anfertigen.',
        'Anmeldung bei der Meldebehörde vornehmen.',
      ],
      nextStepsAr: [
        'راجع كل بيانات العقد بعناية.',
        'سجّل بداية الإيجار وقيمة الكفالة.',
        'أعدّ محضر تسليم الشقة.',
        'سجّل عنوانك في دائرة السكان.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'nebenkostenabrechnung',
      labelDe: 'Nebenkostenabrechnung',
      labelAr: 'تسوية التكاليف الإضافية',
      decisiveKeywords: [
        'Nebenkostenabrechnung',
        'Betriebskostenabrechnung',
        'Nachzahlung Nebenkosten',
        'Abrechnungszeitraum',
      ],
      supportingKeywords: ['Heizung', 'Wasser', 'Vorauszahlung', 'Abrechnung'],
      negativeKeywords: ['Steuerbescheid', 'Inkasso', 'Mahnbescheid'],
      nextStepsDe: [
        'Abrechnungszeitraum und Positionen prüfen.',
        'Nachzahlung oder Gutschrift notieren.',
        'Bei Unklarheiten innerhalb von 12 Monaten Einspruch einlegen.',
        'Nachzahlung rechtzeitig begleichen.',
      ],
      nextStepsAr: [
        'راجع فترة المحاسبة والبنود.',
        'سجّل المبلغ الإضافي أو الرصيد المستحق.',
        'قدّم اعتراضًا خلال 12 شهرًا عند الشك.',
        'ادفع المبلغ الإضافي في الوقت المحدد.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'mieterhoehung',
      labelDe: 'Mieterhöhung',
      labelAr: 'زيادة الإيجار',
      decisiveKeywords: ['Mieterhöhung', 'monatliche Miete', 'erhöht sich'],
      supportingKeywords: ['Mietvertrag', 'neue Miethöhe', 'Vermieter'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Neue Miethöhe und Datum des Inkrafttretens prüfen.',
        'Prüfen, ob die Erhöhung rechtmäßig ist (Mietspiegel).',
        'Zustimmung geben oder widersprechen (innerhalb der gesetzlichen Frist).',
      ],
      nextStepsAr: [
        'راجع قيمة الإيجار الجديدة وتاريخ تطبيقها.',
        'تحقق مما إذا كانت الزيادة قانونية (مقارنةً بمؤشر الإيجارات).',
        'وافق أو اعترض خلال المهلة القانونية.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'kaution',
      labelDe: 'Mietkaution',
      labelAr: 'كفالة الإيجار',
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
      nextStepsDe: [
        'Kautionsbetrag im Mietvertrag prüfen.',
        'Kautionszahlungsbeleg aufbewahren.',
        'Bei Kautionsabrechnung: Abzüge prüfen und ggf. widersprechen.',
        'Rückzahlung innerhalb von 3–6 Monaten nach Auszug erwarten.',
      ],
      nextStepsAr: [
        'تحقق من قيمة الكفالة في عقد الإيجار.',
        'احتفظ بإيصال دفع الكفالة.',
        'عند تسوية الكفالة: راجع الخصومات واعترض إذا لزم.',
        'توقع استرداد الكفالة خلال 3-6 أشهر بعد المغادرة.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // VERSICHERUNG (General)
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'versicherung_schein',
      labelDe: 'Versicherungsschein / Police',
      labelAr: 'وثيقة التأمين',
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
      nextStepsDe: [
        'Versicherungsschein sicher aufbewahren.',
        'Vertragsdaten und Deckungsumfang prüfen.',
        'Beginn und eventuelle Kündigungsfristen notieren.',
      ],
      nextStepsAr: [
        'احفظ وثيقة التأمين في مكان آمن.',
        'راجع بيانات العقد ونطاق التغطية.',
        'سجّل تاريخ البداية ومهل الإلغاء.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'versicherung_beitrag',
      labelDe: 'Versicherung – Beitragsrechnung',
      labelAr: 'التأمين – فاتورة القسط',
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
      nextStepsDe: [
        'Beitrag und Fälligkeitsdatum prüfen.',
        'Pünktlich zahlen – Nichtbezahlen kann zum Verlust des Versicherungsschutzes führen.',
      ],
      nextStepsAr: [
        'راجع القسط وموعد الاستحقاق.',
        'ادفع في الوقت المحدد – عدم الدفع قد يُلغي التغطية التأمينية.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'versicherung_schaden_meldung',
      labelDe: 'Versicherung – Schadenmeldung Bestätigung',
      labelAr: 'التأمين – تأكيد استلام بلاغ الحادث',
      decisiveKeywords: [
        'Schadenmeldung',
        'Schadennummer',
        'Eingang Ihrer Schadenmeldung',
      ],
      supportingKeywords: ['Schadenfall', 'Prüfung', 'Bearbeitung'],
      negativeKeywords: ['Rechnung', 'Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Schadennummer notieren.',
        'Alle Unterlagen und Fotos zum Schaden aufbewahren.',
        'Auf Rückmeldung der Versicherung warten.',
      ],
      nextStepsAr: [
        'سجّل رقم الحادث.',
        'احتفظ بجميع المستندات والصور المتعلقة بالحادث.',
        'انتظر رد شركة التأمين.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'versicherung_schaden_ablehnung',
      labelDe: 'Versicherung – Schadenablehnung',
      labelAr: 'التأمين – رفض تعويض الحادث',
      decisiveKeywords: ['Ablehnung', 'keine Leistung', 'Versicherungsschutz'],
      supportingKeywords: ['Schadenfall', 'Grund', 'Prüfung'],
      negativeKeywords: ['Rechnung', 'Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Ablehnungsgrund sorgfältig lesen.',
        'Beweise und Unterlagen sammeln.',
        'Innerhalb der Widerspruchsfrist Beschwerde einlegen.',
        'Bei Bedarf Rechtsschutzversicherung oder Anwalt einschalten.',
      ],
      nextStepsAr: [
        'اقرأ سبب الرفض بعناية.',
        'اجمع الأدلة والمستندات.',
        'قدّم اعتراضًا خلال مهلة الطعن.',
        'إذا لزم، استعن بتأمين الحماية القانونية أو محامٍ.',
      ],
      riskLevel: RiskLevel.high,
    ),
    CategoryDefinition(
      id: 'versicherung_kuendigung',
      labelDe: 'Versicherung – Kündigungsbestätigung',
      labelAr: 'التأمين – تأكيد إلغاء العقد',
      decisiveKeywords: [
        'Kündigungsbestätigung',
        'Eingang Ihrer Kündigung',
        'Vertrag endet',
      ],
      supportingKeywords: ['Versicherung', 'Kündigung', 'Vertragsende'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Vertragsende und letzten Versicherungstag notieren.',
        'Sicherstellen, dass eine Anschlussversicherung besteht.',
        'Bestätigung aufbewahren.',
      ],
      nextStepsAr: [
        'سجّل تاريخ انتهاء العقد وآخر يوم تأمين.',
        'تأكد من وجود تأمين بديل.',
        'احتفظ بتأكيد الإلغاء.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // KFZ
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'kfz_evb',
      labelDe: 'Kfz-Versicherung – eVB',
      labelAr: 'تأمين السيارة – رقم eVB للتسجيل',
      decisiveKeywords: [
        'eVB',
        'Elektronische Versicherungsbestätigung',
        'eVB-Nummer',
        'Zulassung',
      ],
      supportingKeywords: ['Fahrzeugzulassung', 'Zulassungsstelle'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'eVB-Nummer bei der Zulassungsstelle angeben.',
        'Nummer aufbewahren bis die Zulassung abgeschlossen ist.',
      ],
      nextStepsAr: [
        'أدخل رقم eVB في دائرة الترخيص.',
        'احتفظ بالرقم حتى اكتمال التسجيل.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'kfz_schaden',
      labelDe: 'Kfz-Versicherung – Schadenmeldung',
      labelAr: 'تأمين السيارة – بلاغ حادث',
      decisiveKeywords: ['Kfz-Schaden', 'Schadennummer Kfz', 'Kfz-Schadenfall'],
      supportingKeywords: ['Schadenmeldung', 'Fahrzeug', 'Unfall'],
      negativeKeywords: ['Rechnung', 'Mahnung'],
      nextStepsDe: [
        'Alle Unfallfotos und Unterlagen aufbewahren.',
        'Reparaturauftrag nicht ohne Genehmigung der Versicherung erteilen.',
        'Auf Regulierungsentscheid warten.',
      ],
      nextStepsAr: [
        'احتفظ بكل صور وأوراق الحادث.',
        'لا تطلب إصلاح السيارة قبل موافقة شركة التأمين.',
        'انتظر قرار التعويض.',
      ],
      riskLevel: RiskLevel.medium,
    ),

    // ─────────────────────────────────────────────────────────────────────
    // VERTRÄGE
    // ─────────────────────────────────────────────────────────────────────
    CategoryDefinition(
      id: 'vertrag_kuendigung',
      labelDe: 'Vertragskündigung / Kündigungsbestätigung',
      labelAr: 'إلغاء عقد أو تأكيد إلغائه',
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
      nextStepsDe: [
        'Vertragsende und eventuelle Restlaufzeit prüfen.',
        'Rückgabe von Geräten oder Materialien (falls nötig) planen.',
        'Kündigung aufbewahren als Nachweis.',
      ],
      nextStepsAr: [
        'راجع تاريخ انتهاء العقد وأي فترة متبقية.',
        'خطّط لإعادة الأجهزة أو المواد إذا لزم.',
        'احتفظ بالإلغاء كإثبات.',
      ],
      riskLevel: RiskLevel.low,
    ),
    CategoryDefinition(
      id: 'vertrag_verlaengerung',
      labelDe: 'Automatische Vertragsverlängerung',
      labelAr: 'تمديد تلقائي للعقد',
      decisiveKeywords: [
        'Vertragsverlängerung',
        'verlängert sich automatisch',
        'Verlängerung des Vertrags',
      ],
      supportingKeywords: ['Laufzeit', 'automatisch', 'Vertrag'],
      negativeKeywords: ['Mahnung', 'Inkasso'],
      nextStepsDe: [
        'Prüfen, ob Sie den Vertrag behalten oder kündigen möchten.',
        'Kündigungsfrist einhalten, um automatische Verlängerung zu verhindern.',
      ],
      nextStepsAr: [
        'قرّر ما إذا كنت تريد الاستمرار أو الإلغاء.',
        'الزم مهلة الإلغاء لتفادي التمديد التلقائي.',
      ],
      riskLevel: RiskLevel.medium,
    ),
    CategoryDefinition(
      id: 'arbeitsvertrag',
      labelDe: 'Arbeitsvertrag',
      labelAr: 'عقد عمل',
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
      nextStepsDe: [
        'Vertrag vollständig lesen – Gehalt, Urlaub, Probezeit, Kündigungsfristen.',
        'Unterschriebene Kopie vom Arbeitgeber anfordern.',
        'Sozialversicherung und Krankenkasse informieren.',
      ],
      nextStepsAr: [
        'اقرأ العقد بالكامل – الراتب، الإجازة، فترة التجربة، مهل الإلغاء.',
        'اطلب نسخة موقّعة من صاحب العمل.',
        'أبلغ التأمين الاجتماعي وشركة التأمين الصحي.',
      ],
      riskLevel: RiskLevel.low,
    ),
  ];
}
