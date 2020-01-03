require.context("govuk-frontend/govuk/assets");
import { initAll as govUKFrontendInitAll } from "govuk-frontend";
import initNationalityAutocomplete from "./nationality-autocomplete";
import initCoursesAutocomplete from "./courses-autocomplete";
import cookieMessage from "./cookie-banner";

import "accessible-autocomplete/dist/accessible-autocomplete.min.css";
import "../styles/application.scss";
govUKFrontendInitAll();

initNationalityAutocomplete();
initCoursesAutocomplete();

var $cookieMessage = document.querySelector('[data-module="cookie-message"]');
new cookieMessage($cookieMessage).init();
