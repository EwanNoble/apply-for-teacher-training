FactoryBot.define do
  factory :application_qualification do
    application_form
    level { %w[degree gcse other].sample }
    qualification_type { %w[BA Masters A-Level gcse].sample }
    subject { Faker::Educator.subject }
    grade { %w[A B].sample }
    predicted_grade { %w[true false].sample }
    award_year { Faker::Date.between(from: 10.years.ago, to: 1.year.ago).year }
    institution_name { Faker::University.name }
    institution_country { Faker::Address.country_code }
    equivalency_details { Faker::Lorem.paragraph_by_chars(number: 200) }

    factory :gcse_qualification do
      level { 'gcse' }
      qualification_type { 'gcse' }
      subject { %w[maths english science].sample }
      grade { %w[A B C].sample }
      predicted_grade { false }
      award_year { Faker::Date.between(from: 10.years.ago, to: 8.years.ago).year }

      trait :non_uk do
        qualification_type { 'non_uk' }
        non_uk_qualification_type { 'High School Diploma' }
        grade { %w[pass merit distinction].sample }
        institution_country { Faker::Address.country_code }
        enic_reference { '4000123456' }
        comparable_uk_qualification { 'Between GCSE and GCSE AS Level' }
      end

      trait :missing_and_currently_completing do
        qualification_type { 'missing' }
        grade { nil }
        predicted_grade { nil }
        award_year { nil }
        currently_completing_qualification { true }
        not_completed_explanation { 'I will be taking an equivalency test in a few weeks' }
      end

      trait :missing_and_not_currently_completing do
        qualification_type { 'missing' }
        grade { nil }
        predicted_grade { nil }
        award_year { nil }
        currently_completing_qualification { false }
        missing_explanation { 'I have 10 years experience teaching English Language' }
      end

      trait :multiple_english_gcses do
        grade { nil }
        subject { 'english' }
        constituent_grades { { english_language: { grade: 'A', public_id: 120282 }, english_literature: { grade: 'D', public_id: 120283 } } }
      end
    end

    factory :degree_qualification do
      level { 'degree' }
      qualification_type { Hesa::DegreeType.all.sample.name }
      subject { Hesa::Subject.all.sample.name }
      institution_name { Hesa::Institution.all.sample.name }
      grade { Hesa::Grade.all.sample.description }
      start_year { Faker::Date.between(from: 5.years.ago, to: 3.years.ago).year }
      award_year { Faker::Date.between(from: 2.years.ago, to: 1.year.ago).year }

      after(:build) do |degree, _evaluator|
        degree.qualification_type_hesa_code = Hesa::DegreeType.find_by_name(degree.qualification_type)&.hesa_code
        degree.subject_hesa_code = Hesa::Subject.find_by_name(degree.subject)&.hesa_code
        degree.institution_hesa_code = Hesa::Institution.find_by_name(degree.institution_name)&.hesa_code
        degree.grade_hesa_code = Hesa::Grade.find_by_description(degree.grade)&.hesa_code
      end
    end

    factory :other_qualification do
      level { 'other' }
      qualification_type { 'Other' }
      other_uk_qualification_type { Faker::Educator.subject }
      subject { Faker::Educator.subject }
      institution_name { Faker::University.name }
      grade { %w[pass merit distinction].sample }
      predicted_grade { false }
      institution_country { 'GB' }
      award_year { Faker::Date.between(from: 7.years.ago, to: 6.years.ago).year }

      trait :non_uk do
        level { 'other' }
        qualification_type { 'non_uk' }
        non_uk_qualification_type { Faker::Educator.subject }
        subject { Faker::Educator.subject }
        institution_name { Faker::University.name }
        grade { %w[pass merit distinction].sample }
        institution_country { Faker::Address.country_code }
      end
    end
  end
end
