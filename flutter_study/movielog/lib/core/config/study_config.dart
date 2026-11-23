const studyWeek = int.fromEnvironment('STUDY_WEEK', defaultValue: 9);
const week8 = studyWeek == 8;
const workbookVersion = week8 ? 'v7' : 'v8';
