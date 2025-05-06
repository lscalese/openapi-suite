Class dc.openapi.common.AITools Extends %RegisteredObject
{

Parameter OPENAI = "openai";

Parameter OLLAMA = "ollama";

Parameter DEFAULTOPENAIMODEL = "o4-mini";

Parameter DEFAULTOLLAMAMODEL = "codegemma";

Parameter DEFAULTOLLAMABASEURL = "http://host.docker.internal:10000";

ClassMethod Ask(prompt As %String) As %String
{
    Set response = ""

    ; Set ^openapisuite("settings", "AI", "model") = "o4-mini"
    ; Set ^openapisuite("settings", "AI", "provider") = "openai"
    ; Set ^openapisuite("settings", "AI", "base_url") = "http://host.docker.internal:10000"   

    Set provider = $g(^openapisuite("settings", "AI", "provider"),..#OLLAMA)

    If provider = ..#OPENAI {
        Set model = $g(^openapisuite("settings", "AI", "model"), ..#DEFAULTOPENAIMODEL)
        Set response = ..AskWithOpenAI(prompt)
    }
    ElseIf provider = ..#OLLAMA {
        Set url = $g(^openapisuite("settings", "AI", "ollama_base_url"), ..#DEFAULTOLLAMABASEURL)
        Set model = $g(^openapisuite("settings", "AI", "model"), ..#DEFAULTOLLAMAMODEL)
        Set response = ..AskWithOllama(prompt, url, model)
    }
    Else {

    }

    Write !, response

    Return response
}

ClassMethod AskWithOllama(prompt As %String, url As %String, model As %String) As %String [ Language = python ]
{
    from langchain_community.llms import Ollama
    ollama = Ollama(
        base_url=str(url),
        model=str(model)
    )
    print(str(prompt))
    return str(ollama.invoke(str(prompt)))
}

ClassMethod AskWithOpenAI(prompt As %String, model As %String, apiKey As %String = "") As %String [ Language = python ]
{
    import os
    from langchain_openai import ChatOpenAI
    
    # Set API key from parameter or environment variable
    if apiKey:
        os.environ["OPENAI_API_KEY"] = apiKey
    
    # Initialize the OpenAI model
    llm = ChatOpenAI(
        model=str(model),
        temperature=0.7
    )
    
    # Invoke the model and print the response
    response = llm.invoke(str(prompt))
    return str(response.content)
}

}
