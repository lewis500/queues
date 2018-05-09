module Hello
using Distributions
mutable struct Car
    traveled::Int16
    history::Vector{Int16}
    t_arrival::Int16
    t_exit::Int16
    function Car(time)
        new(time,[],0,0)
    end
end

mutable struct Queue
    ID::Int16
    cars::Vector{Car}
    nextTime::Float64
    history::Vector{Tuple{Int16,Int16}}
    function Queue(ID,nextTime)
         new(ID,[],nextTime,[])
     end
end

mutable struct Simulation
    N::Int16
    cycle::Int16
    green_time::Int16
    trip_length::Int16
    saturation::Float64
    arrival_rate::Float64
    interval_generator::ContinuousUnivariateDistribution
    cars::Vector{Car}
    exited::Vector{Car}
    queues::Vector{Queue}
    green::Bool
    time::Int16
    function Simulation(
        saturation=0.85;
        N =20,
        cycle=30,
        green_time=15,
        trip_length=10,
    )
        arrival_rate = saturation*green_time/(trip_length*cycle)
        interval_generator = Exponential(1./arrival_rate)
        queues = [Queue(v,getNextTime(interval_generator,0)) for v=1:N]
        new(N,cycle,green_time,trip_length,saturation,arrival_rate,interval_generator,[],[],queues,false,0)
    end
end

getNextTime(i::ContinuousUnivariateDistribution,time) = rand(i)+time
#
function tick(s::Simulation)
    s.time+=1
    if s.time%s.green_time == 0
        s.green = !s.green
    end

    if s.green
        switches = []
        for (i,queue)=enumerate(s.queues)
            if length(queue.cars)>0
                car = pop!(queue.cars)
                push!(car.history,queue.ID)
                car.traveled+=1
                if car.traveled < s.trip_length
                    nextQueue = i == s.N ? s.queues[1] : s.queues[i+1]
                    push!(switches,(car,nextQueue.cars))
                else
                    car.t_exit = s.time
                    push!(s.exited,car)
                end
            end
        end
        for switch = switches
            unshift!(switch[2],switch[1])
        end
    end

    for queue = s.queues
        if queue.nextTime <= s.time
            car = Car(s.time)
            push!(s.cars,car)
            unshift!(queue.cars,car)
            queue.nextTime = s.time + -log(rand())/s.arrival_rate
        end
    end
end

end

s = Hello.Simulation(.85)

for i=1:1000
    Hello.tick(s)
end
