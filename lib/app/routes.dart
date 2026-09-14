abstract final class Routes {
  static const splash = '/';
  static const exams = '/onboarding';
  static const goal = '/onboarding/goal';
  static const value = '/onboarding/value';
  static const auth = '/auth';
  static const home = '/home';
  static const plan = '/plan';
  static const statistics = '/statistics';
  static const notebook = '/notebook';
  static const myQuestions = notebook;
  static const questionDetailPattern = '/questions/:id';
  static const questionEditPattern = '/questions/:id/edit';
  static String questionDetail(String id) => '/questions/$id';
  static String questionEdit(String id) => '/questions/$id/edit';
  static const more = '/more';
  static const profile = more;
  static const capture = '/question/capture';
  static const confirm = '/question/confirm';
  static const topics = '/question/topics';
  static const drawing = '/drawing';
  static const review = '/review';
  static const reviewSessionPattern = '/review/session/:id';
  static String reviewSession(String id) => '/review/session/$id';
}
