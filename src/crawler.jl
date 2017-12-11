#Crawler model, for the module, should work

using Requests
using HTTP
using Gumbo
using AbstractTrees
using ArgParse

#define our crawler

type Crawler
    startUrl::AbstractString
    urlsVisited::Array{AbstractString}
    urlsToCrawl::Array{AbstractString}
    content::Dict{AbstractString, AbstractString}
    #the content is dictoianry{url: html content}
    breadthFirst::Bool
    
    #constructors
    function Crawler(starturl::AbstractString)
        return new(starturl, AbstractString[], AbstractString[],Dict{AbstractString, AbstractString}(), true)
    end
    function Crawler(starturl::AbstractString, breadthfirst::Bool)
        return new(starturl, AbstractString[],AbstractString[],Dict{AbstractString, AbstractString}(), breadthfirst)
    end
    function Crawler(starturl::AbstractString, urlstocrawl::Array{AbstractString},breadthfirst::Bool)
        return new(starturl, AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), breadthfirst) 
    end
    function Crawler(starturl::AbstractString, urlstocrawl::Array{AbstractString})
        return new(starturl, AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), true)
    end
    #remove this, just a test
    function Crawler(urlstocrawl::Array{AbstractString}, breadthfirst::Bool)
        return new("", AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), breadthfirst)
    end
    function Crawler(urlstocrawl::Array{AbstractString})
        return new("", AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), true)
    end
    
end




function crawl(crawler::Crawler, num_iterations::Integer=10, verbose=true, save=true)
    #first we check if it's the first thing we see. so we should just check this
    #shall we just define variables from the crawler? nah, let's not. we should just access them consistently
    #as it's meant t be updated in place, I assume
    #we should dump this in thefucntoin so it doesn't slow down
    const successCode = 200
    
    #our immediate return if correct
    if isempty(crawler.urlsToCrawl) && crawler.startUrl==""
        return crawler.content, crawler.urlsVisited
    end
    

    if isempty(crawler.urlsToCrawl) && crawler.startUrl!=""
        #so we are at the beginning so we visit our first piece
        #we set the starturl to urls to crawl
        push!(crawler.urlsToCrawl,crawler.startUrl)
        crawler.startUrl=""
    end
    
    #okay, now we begin the loop
    for i in 0:num_iterations
        #we check if empty we probably shouldn't do this on each iteratino, but oh well!
        if isempty(crawler.urlsToCrawl) && crawler.startUrl==""
            return crawler.content, crawler.urlsVisited
        end
        url = pop!(crawler.urlsToCrawl)
        #we get the content
        #we make the request with http
        #we first check this works... idk
        #println(crawler.urlsVisited)
        #println(crawler.urlsToCrawl)
        if !(url in crawler.urlsVisited)

            if verbose==true
                println("requesting $url")
            end 
            try
                
                response = HTTP.get(url)
                #println(response)
                #check success code and procede if correct
                if response.status==successCode
                    # okay, here's what we do. we do our parsing string here
                    res = String(response.body)
                    doc = parsehtml(res)
                    if verbose == true
                        println("response received and is successful")
                    end

                    #if we succeed we update our links
                    crawler.content[url] = res

                    #print(typeof(url))
                   # println("")
                   # println("type of crawler.urlsvisited ", typeof(crawler.urlsVisited))
                   # println("url: ", url)
                   # println(crawler.urlsVisited)
                    push!(crawler.urlsVisited, url)

                    #we go through all elements get links
                    for elem in PostOrderDFS(doc.root)
                        if typeof(elem) == Gumbo.HTMLElement{:a}
                            link=get(elem.attributes, "href","#")
                            if link != "#"
                                #then it's succeeded we have link
                               # println(typeof(link))
                                push!(crawler.urlsToCrawl, link)
                            end
                        end
                    end
                end
                if url in crawler.urlsToCrawl
                    println("repeat url")
                    num_iterations +=1
                end
            end
        end
    end
    
    #now once we're finished our loop
    #we return stuff and save
    
    if save==true
        #we save the files somewhere
    end
    return crawler.content, crawler.urlsVisited
end


# this is our arg parse settings so we can see if it works and write it up properly

function parse_commandline()

    s = ArgParseSettings(prog="Julia Web Crawler",
                        description="A webcrawler written in Julia",
                        commands_are_required=false,
                        version="0.0.1",
                        add_version=true)

    @add_arg_table s begin
            "--urls"
                help="either a url to start at or a set of urls to start visiting"
                required=true
            "--breadth-first", "--b"
                help="a flag or whether the crawler should search depth or breadth first"
                action=:store_true
                default = true
            "--num_iterations", "--i"
                help="the number of iteratinos to run the crawler for"
                default=10
    end
    return parse_args(s)
end

function setupCrawler(urls, b=true)
    return Crawler(urls, b)
end

function begin_crawl(urls, b=true, num_iterations::Integer=10)
	crawler = setupCrawler(urls, b)
	crawl(crawler, num_iterations, b)
end
	
