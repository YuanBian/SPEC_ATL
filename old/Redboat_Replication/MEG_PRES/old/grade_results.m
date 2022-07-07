function [accuracy] = grade_results(results, correct)
    graded = cell2mat(results.Response) == cell2mat(correct);
    accuracy = graded;
end