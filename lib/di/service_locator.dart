import 'package:get_it/get_it.dart';

import '../services/interfaces/interfaces.dart';
import '../services/database_service.dart';
import '../services/backend_ffi_service.dart';
import '../services/price_api_service.dart';
import '../services/google_auth_service.dart';
import '../services/backup_service.dart';
import '../services/user_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/bill_service.dart';
import '../services/investment_service.dart';
import '../services/sync_manager.dart';
import '../services/consent_service.dart';
import '../services/budget_service.dart';
import '../services/budget_notification_service.dart';
import '../services/budget_migration_service.dart';
import '../transaction_service.dart';
import '../services/ai_service.dart';
import '../services/ai_category_pipeline.dart';
import '../services/ocr_service.dart';
import '../services/insights_service.dart';
import '../services/report_ai_service.dart';
import '../services/report_pdf_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Tier 0: Leaf services (no service dependencies)
  sl.registerLazySingleton<IDatabaseService>(() => DatabaseService());
  sl.registerLazySingleton<IBackendFfiService>(() => BackendFfiService());
  sl.registerLazySingleton<IPriceApiService>(() => PriceApiService());
  sl.registerLazySingleton<IGoogleAuthService>(() => GoogleAuthService());
  sl.registerLazySingleton<IBackupService>(() => BackupService());
  sl.registerLazySingleton<IConsentService>(() => ConsentService());

  // Tier 1: Services depending on Tier 0
  sl.registerLazySingleton<IUserService>(
    () => UserService(db: sl<IDatabaseService>()),
  );
  sl.registerLazySingleton<IProfileService>(
    () => ProfileService(db: sl<IDatabaseService>()),
  );
  sl.registerLazySingleton<ISettingsService>(
    () => SettingsService(db: sl<IDatabaseService>()),
  );
  sl.registerLazySingleton<IBillService>(
    () => BillService(db: sl<IDatabaseService>()),
  );
  sl.registerLazySingleton<ITransactionService>(
    () => TransactionService(
      ffiService: sl<IBackendFfiService>(),
      db: sl<IDatabaseService>(),
    ),
  );
  sl.registerLazySingleton<IInvestmentService>(
    () => InvestmentService(
      ffiService: sl<IBackendFfiService>(),
      priceService: sl<IPriceApiService>(),
      dbService: sl<IDatabaseService>(),
    ),
  );
  sl.registerLazySingleton<IBudgetService>(
    () => BudgetService(db: sl<IDatabaseService>()),
  );
  sl.registerLazySingleton<IAIService>(
    () => AIService(),
  );
  sl.registerLazySingleton<OCRService>(() => OCRService());
  sl.registerLazySingleton<IAICategoryPipeline>(
    () => AICategoryPipeline(
      aiService: sl<IAIService>(),
      ocrService: sl<OCRService>(),
    ),
  );
  sl.registerLazySingleton<IInsightsService>(() => InsightsService());
  sl.registerLazySingleton<IReportAiService>(() => ReportAiService());
  sl.registerLazySingleton<IReportPdfService>(() => ReportPdfService());

  // Tier 2: Top-tier services
  sl.registerLazySingleton<ISyncManager>(
    () => SyncManager(backupService: sl<IBackupService>()),
  );
  sl.registerLazySingleton<BudgetNotificationService>(
    () => BudgetNotificationService(budgetService: sl<IBudgetService>()),
  );
  sl.registerLazySingleton<BudgetMigrationService>(
    () => BudgetMigrationService(budgetService: sl<IBudgetService>()),
  );
}

/// Reset all registrations (for tests)
Future<void> resetServiceLocator() async {
  await sl.reset();
}
