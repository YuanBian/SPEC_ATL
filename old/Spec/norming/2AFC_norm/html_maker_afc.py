import re
code = input("Enter code: ")
num_items = int(input("How many trials on the survey? "))
survey_name = input("What do you want to call the output file? ")
header = re.sub("<CODE>", code, """
<style>
input[type="number"]::-webkit-outer-spin-button,
input[type="number"]::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
}
input[type="number"] {
    -moz-appearance: textfield;
}
</style>

<script type="text/javascript">

function stopRKey(evt) {
  var evt = (evt) ? evt : ((event) ? event : null);
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
  if ((evt.keyCode == 13) && (node.type=="text"))  {return false;}
}

document.onkeypress = stopRKey;

</script>

<h1>Sentence understanding</h1>

<p>&nbsp;</p>

<p><font color="red"><b>SURVEY CODE:<CODE> </b></font></p>


<p><font color="red"><i><b>PLEASE COMPLETE ONLY ONE&nbsp;</b><b>SURVEY WITH CODE </b><b><CODE></b><b>.&nbsp; YOU WILL NOT BE PAID FOR COMPLETING MORE THAN ONE SURVEY WITH THIS CODE.</b></i></font></p>

<p>&nbsp;</p>

<p>&nbsp;</p>

<p>Consent Statement<br />
<br />
By answering the following questions, you are participating in a study being performed by cognitive scientists in the MIT Department of Brain and Cognitive Science. If you have questions about this research, please contact Edward Gibson at egibson@mit.edu. Your participation in this research is voluntary. You may decline to answer any or all of the following questions. You may decline further participation, at any time, without adverse consequences. Your anonymity is assured; the researchers who have requested your participation will not receive any personal information about you.&nbsp;</p>

<p>Please answer the background questions below. The only restriction to being paid is achieving the accuracy requirements listed below. Payment is NOT dependent on your answers to the following background questions on country and language.</p>

<p>What country are you from? <input name="country" type="radio" value="USA" /><span class="answertext">USA </span>&nbsp;&nbsp;&nbsp; <input name="country" type="radio" value="CAN" /><span class="answertext">Canada</span>&nbsp; &nbsp; <input name="country" type="radio" value="UK" /><span class="answertext">UK &nbsp; &nbsp; </span><input name="country" type="radio" value="AUS" />Australia / New Zealand &nbsp;&nbsp;&nbsp;&nbsp;<input name="country" type="radio" value="IND" /><span class="answertext">India&nbsp; &nbsp; </span><input name="country" type="radio" value="OTHER" /><span class="answertext">Other&nbsp;&nbsp;</span></p>

<p>Is English your first language? <input name="English" type="radio" value="yes" /><span class="answertext"> Yes </span>&nbsp;&nbsp;&nbsp;<input name="English" type="radio" value="no" /><span class="answertext">No</span></p>

<p>What is your gender? <input name="gender" type="radio" value="Female" /><span class="answertext"> Female </span>&nbsp;&nbsp;&nbsp;<input name="gender" type="radio" value="Male" /><span class="answertext">Male</span>&nbsp;&nbsp;&nbsp;<input name="gender" type="radio" value="Other" /><span class="answertext">Other</span></p>

<p>what is your age? (Enter number) <input type="number" name="age" min="1" max="100" step="1"/><span class="answertext"></p>

<h2>Instructions</h2>

<p><i>Please read the question, and choose the option you think is right.</i></p>

<p><i>Words vary a lot in how specific they are in their meanings. Some words are very broad, like “thing” or “entity” or “person”, others are much more specific, like “scallop” or “desk lamp” or “truck driver”. You can think of the breadth of a word’s meaning in terms of how many things/entities in the world the word can apply to (more things/entities > broader meaning).</i></p>

<p><i>In this study, you will see 100 pairs words. One word in each pair will be broader in meaning. Your task to chose  — for each pair — the word that is broader in meaning. If you are not sure, just make your best guess. This HIT contains a number of catch trials which we expect everyone to be able to answer correctly. If you don’t answer most of these correctly, you will not get paid. 

</i></p>
<br />
---------------------------------------------------------------------------------------------------------------</p>""")

f = open(survey_name, "w")
f.write(header + "\n")

for i in range(1, num_items + 1):
    f.write("""<p id="${code__%(num)s}__%(num)s"></p>
    <p ><b>Question:</b> choose the word that is broader in meaning</p>
<p><input type="radio" value="1" name="Rating__%(num)s" /><span class="answertext">${optA__%(num)s} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></p> 
<p><input type="radio" value="2" name="Rating__%(num)s"  /><span class="answertext">${optB__%(num)s} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></p>
<p>---------------------------------------------------------------------------------------------------------------</p>""" %{"num":i})
    f.write("\n")

f.write("""<p>---------------------------------------------------------------------------------------------------------------</p>
<p><b><br />
</b>Please leave any comments here.</p>
<p><textarea name="answer" cols="80" rows="3"></textarea></p>""")

f.close()
