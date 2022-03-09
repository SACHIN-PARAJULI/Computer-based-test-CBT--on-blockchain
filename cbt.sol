// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract CBT {
    using SafeCast for uint;

    address public examController;
    uint public questionNo = 0;
    uint public questionAdderNo = 0;

    uint INFINITY = 4947467456361712643878159949688225191027818877269170197894512257892546715500;

    event QuestionAdderCreated(address indexed _from, string status);

    struct Question{
        string question;
        string[] options;
        uint answer;
        address added_by;
    }

    struct QuestionAdder{
        address addr;
        string name;
        string speciality;
    }

    mapping(uint=>Question) public questions;
    mapping(uint=>uint) public questionHashMap;
    uint[] public questionHashes;
    mapping(uint=> uint) globalQuestionWeights;

    mapping(uint=>QuestionAdder) questionAdders;


    mapping(uint => uint) tempHashes;
    mapping(uint => uint) hashWeights;

    mapping(address => uint[]) public userAskedQuestions;
    mapping(address => uint) public usersObtainedMarks;
    address[] checkedAddresses;
    uint[] checkedMarks;
    string[] option;

    int[] public hashDifferences;

    event QuestionHashes(address indexed userAddress, string questionHashes);
    event QuestionRetrieved(address indexed userAddress, uint questionHash ,string question);
    event AnswerChecked(address indexed userAddress, uint marks);
    event RankObtained(address indexed userAddress, uint rank);


    constructor (){
        examController = msg.sender;

        option.push("Option 1");
        option.push("Option 2");
        option.push("Option 3");
        option.push("Option 4");

        addQuestion("Who is the father of computer?", option, 1);
        addQuestion("Who is the president of coca cola?", option, 1);
        addQuestion("Who invented dildo?", option, 1);
        addQuestion("What is your father put is your name?", option, 1);

        addQuestion("Who is the playboy?", option, 1);
        addQuestion("Where is my home?", option, 1);
        addQuestion("Phateko kattu kaslae dis?", option, 1);
        addQuestion("Laune bela ma tain this?", option, 1);
        addQuestion("What is this?", option, 1);
    }

    function addQuestionAdder(address questionAdderAddress, string memory name, string memory speciality) public {
        questionAdders[questionAdderNo] = QuestionAdder(questionAdderAddress, name, speciality);
        questionAdderNo++;
        emit QuestionAdderCreated(msg.sender, "Question Adder Created");
    }

    function addQuestion(string memory question, string[] memory options, uint answer) public  {
        bool isQuestionAdder = false;
        for (uint i = 0; i<= questionAdderNo; i++){
            if (questionAdders[i].addr == msg.sender){
                isQuestionAdder = true;
            }
        }

        // require(isQuestionAdder, "Address not permitted to add question.");

        string memory smashedOptions = "";
        for (uint i = 0; i < options.length; i++){
            smashedOptions = string(abi.encodePacked(smashedOptions, options[i]));
        }

        string memory questionHashSeed = Strings.toString(uint(keccak256(abi.encodePacked(question))));
        string memory answerHashSeed = Strings.toString(uint(keccak256(abi.encode(answer))));

        string memory hashSeed = string(abi.encodePacked(questionHashSeed, answerHashSeed));
        uint questionHash = uint(keccak256(abi.encodePacked(hashSeed))) /100;

        questions[questionHash] = Question(question, options, answer, msg.sender);
        questionHashMap[questionNo] = questionHash;
        questionHashes.push(questionHash);

        globalQuestionWeights[questionHash] = 0;

        questionHashes = sort(questionHashes);

        questionNo++;

    }

    

    function retrieveRandomQuestions() public {
        uint userHash = uint(keccak256(abi.encodePacked(msg.sender)))/100;
        
        int hashDifference;
        uint smallestDifference = INFINITY;
        uint nearestQuestionIndex;
        for(uint i = 0; i < questionHashes.length; i++){
            hashDifference = int(questionHashes[i]) - int(userHash);
            hashDifference = hashDifference >=0 ? hashDifference : -hashDifference;
            if (hashDifference < int(smallestDifference)){
                smallestDifference = uint(hashDifference);
                nearestQuestionIndex = i;
            }
        }

        uint hashNo = 0;
        uint maxWeight = 0;

        uint[] memory questionWeights;
        require(questionHashes.length >= 4, "At least 4 questions required.");
        for (uint i = 1; i <= (questionHashes.length/2-1); i++){

            (bool safe, uint leftIndex) = SafeMath.trySub(nearestQuestionIndex, i);
            uint rightIndex = ((nearestQuestionIndex + i) >= questionHashes.length) ? nearestQuestionIndex : nearestQuestionIndex + i;

            for(uint j = 0; j < hashNo; j++ ){
                if (hashWeights[tempHashes[j]] < maxWeight){
                    maxWeight = hashWeights[tempHashes[j]];
                }
            }

            if (i < maxWeight || hashNo <= 5){
                tempHashes[hashNo] = questionHashes[leftIndex];
                hashWeights[tempHashes[hashNo]] =  i + globalQuestionWeights[questionHashes[leftIndex]];
                hashNo++;

                tempHashes[hashNo] = questionHashes[rightIndex];
                hashWeights[tempHashes[hashNo]] =  i + globalQuestionWeights[questionHashes[rightIndex]];
                hashNo++;
            }

        }

        string memory userQuestionHashes = "";
        string memory space = " ";

        uint[5] memory userQuestions;

        for (uint k= 0; k< hashNo; k++){
            if (k < 5) {
            userQuestionHashes = string(abi.encodePacked(userQuestionHashes, Strings.toString(tempHashes[k])));
            userQuestionHashes = string(abi.encodePacked(userQuestionHashes, space));

            userQuestions[k] = tempHashes[k];
            }
        }

        userAskedQuestions[msg.sender] = userQuestions;

        emit QuestionHashes(msg.sender, userQuestionHashes);
    }

    function retrieveQuestion(uint[] memory questionhashes, uint randomId) public{


        string memory questionSmash = "";
        string memory paddingIntraQuestion = "--";
        string memory paddingInterQuestion = "---";

        for (uint j = 0; j < questionhashes.length; j++){
            Question memory question = questions[questionhashes[j]];

            for (uint i = 0; i < question.options.length; i++){
                questionSmash = string(abi.encodePacked(questionSmash, question.options[i]));
                questionSmash = string(abi.encodePacked(questionSmash, paddingIntraQuestion));
            }

            questionSmash = string(abi.encodePacked(questionSmash, question.question));
            questionSmash = string(abi.encodePacked(questionSmash, paddingInterQuestion));
        }
        emit QuestionRetrieved(msg.sender, randomId, questionSmash);
    }

    function checkAnswer(uint[] memory answers) public {
        require(answers.length == userAskedQuestions[msg.sender].length, "Length of answers do not match.");

        uint obtainedMarks = 0;
        for (uint i = 0; i< answers.length; i++){
            Question memory question = questions[userAskedQuestions[msg.sender][i]];
            if (answers[i] == question.answer){
                obtainedMarks++;
            }
        }

        usersObtainedMarks[msg.sender] = obtainedMarks; 
        checkedAddresses.push(msg.sender);
        checkedMarks.push(obtainedMarks);
        emit AnswerChecked(msg.sender, obtainedMarks);
    }

    function getRank() public {
        checkedMarks = sort(checkedMarks);
        uint rank = 0;
        for(uint i =0 ; i<checkedMarks.length; i++){
            if(usersObtainedMarks[msg.sender] == checkedMarks[i]){
                rank = i;
            }
        }

        rank = checkedMarks.length - rank;

        emit RankObtained(msg.sender, rank);
    }

    function sort(uint[] memory data) public returns(uint[] memory) {
       quickSort(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSort(uint[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

}