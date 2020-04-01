#
# conceptos basicos Kubernetes y ejemplo
#

# lo primero par poder tarabajar con contenedores en wsl ubuntu
# es hacer un update del windows 10 si la bild es inferior a 18917
# una vez este esto , hay que configurar el ubuntu y añadir a apt el
# lo necesario 
https://www.redhat.com/sysadmin/podman-windows-wsl2

. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}_${VERSION_ID}/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt-get update -qq
sudo apt-get -qq -y install podman
sudo mkdir -p /etc/containers
echo -e "[registries.search]\nregistries = ['docker.io', 'quay.io']" | sudo tee /etc/containers/registries.conf

# despues por comodidad de  uso es mejor modificar el fichero de configuracion de podman
#y cambiar el cgroup y el logger
--cgroup-manager cgroupfs --event-logger file



git remote add origin https://github.com/lmtbelmonte/ocp43-fleetman.git
git push -u origin master

/home/lmtbelmonte/k8s-fleetman/k8s-fleetman-webapp-angular

# los ejercicios estan en git 
# DickChesterwood/k8s-fleetman/blob/master/k8s-fleetman-webapp-angular

# accesso al API de kubernetes 
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#-strong-api-overview-strong-
https://goo.gl/cpWuyw

# ejemplo de gestion de flotas con una imagen en docker hub  
k8s-fleetman-webapp-angular

# creamos un projecto inicial
$oc new-project web-app --display-name="Web Team Development" --description="Projecto inicial curso microservicios de Manning"

# creamos el primer manifesto yaml par un webserver nginx
# prototipo inicial solo con una imagen y webpage

apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: webapp
    image: richardchesterwood/k8s-fleetman-webapp-angular:release0

# creamos el objeto en kubernetes
$oc apply -f first-pod.yaml

#inicialmente no hay  acceso externo al pod
#paro se puiede acceder a el como en docker
$oc exec <pod> ls

#acceder a la shell es igual que docker , si lo queremos interactivo ponemos -it
$oc -it exec webapp sh 

#
# SERVICES
#

# ya que la vida de un pod es efimera , hay que recordar que son "cattle" no "pets" hace falta 
# algun tipo de objeto que sea de largo recorrido para que mantenga estable la ip y el puerto 
# independientemente  del pod 
# el servicio perm,ite conectar al cluster y es este el que se ocupa de encontrar el pod/pods
# asociados al servicio.
# esto se hace con etiquetas o LABELS
#
# IMPORTANTE el pod/pods tienen que llevar el mismo label que el vamos a poner en el selector 
# del servicio, este va en la parte de metadatos

apiVersion: v1
kind: Service
metadata:
  # Este nombre es el identificador unico del servicio
  name: fleetman-webapp
spec:
  # Define que pods van a ser representados por este servicio
  # el servicio se convierte en un endpoint
  selector:
    # hace balanceo de carga del trafico con los pods con el mismo label
    app: nginx
  # podriamos crear tambien un tipo loadbalancer que crearia un lb en cloud
  # type: loadbalancer
  # type: ClusterIP - Interno cluster
  # type: NodePort - acceso externo al pod valores port > 30000
  ports:
    - name: http
      port: 80
  type: LoadBalancer

  # el campo type puede tener diferentes valores
  #   - loadBalancer
  #   - ClusterIP
  #       Para el caso de que el servicio queramos que sea interno sin salida al exterior 
  #       como un browser 
  #   - NodePort
  #       Para el caso que queramos exponer el servicio al exterior, es decir NODE o cluster
  #       Hay que identificar en la seccion ports NodePort este tiene que ser un numero 
  #       superior a 30000 , por ejemplo 30080 

-----------------
# Las labels van en metadata y hay que ponerla en el pod !! 
# añadimos labels:
#            app: webapp
# oc apply -f fleetman-webapp.yaml
#como estamos en una instalacion cloud para acceder de forma publica al nuestro pod desde 
# el servicio , hay que crear una ruta , via oc con expose o a traves de la consola
$oc expose service fleetman-webapp

# ahora viene una nueva version , y para evitar downtime vamos a incorporar otra label que contenga la
# version, de esta forma solo cambiando el selector del servicio ira a la nueva version
# es a modo de demo de como  funcionan las labels , la forma correcta o elegante es via 
# deployments

# se puede editar el mismo manifesto del pod y añadir otra con el separador de yaml que son 
# tres - (---) de esta forma identifica que son dos bloques
# solo cambiamos el nombre del pod 

apiVersion: v1
kind: Pod
metadata:
  name: webapp
  labels:
    app: webapp
    release: "0"
spec:
  containers:
  - name: webapp
    image: richardchesterwood/k8s-fleetman-webapp-angular:release0

---

apiVersion: v1
kind: Pod
metadata:
  name: webapp-release-0-5
  labels:
    app: webapp
    release: 0-5 
spec:
  containers:
  - name: webapp
    image: richardchesterwood/k8s-fleetman-webapp-angular:release0-5


# despues modificamos el service para qe el selector lea de la nueva label

apiVersion: v1
kind: Service
metadata:
  name: fleetman-webapp
spec:
  selector:
    app: webapp
    release: "0-5"
  ports:
    - name: http
      port: 80
      NodePort: 30080
  type: NodePort


# al ejecutarlo veremos lo mismos hast qsue cambieamos la label por la nueva release
# esto no afecta a os pods solo re-cablea el servicio para que apunte a lo nuevo
# en el service ponemos 0-5 ( release: 0-5) y ya
$oc apply -f fleetman-webapp

# de esta forma tendremos funcionando la nueva app sin downtime , solo refrescando el 
# navegador ( ctrl F5)
oc get po --show-labels
oc get po --show-labels -l release=0

# Creacion de un pod con un container con una imagen de una cola de mensajes ActiveMQ
# la imagen a utilizar es 
richardchesterwood/k8s-fleetman-queue:release1

# Para la cola de mensajes el puerto es el 8161 , este puerto n se puede exponer al publico,
# tiene que ser un rango entre 30000 - 32767 , para este ejercicio vamos a usar el 30010

# primero creaos el pod y  despuesel servicio

apiVersion: v1
kind: Pod
metadata:
  name: fleetman-queue
  labels:
    app: fleetman-queue
    release: release1 
spec:
  containers:
  - name: webapp
    image: richardchesterwood/k8s-fleetman-queue:release1

# creamos el servicio

apiVersion: v1
kind: Service
metadata:
  name: fleetman-queue
spec:
  selector:
    app: fleetman-queue
    release: release1
  ports:
    - name: queue
      protocol: TCP
      port: 8161
      NodePort: 30010
  type: NodePort

# para actualizar todos los yaml a la vez en un directrio podemos hacer
# oc apply -f . y lo ejecutara pora todos los yaml que encuentre

# hasta ahora hemos tratado directamente con pods , que para ver su funcionamiento es ok pero
# en este caso somos nosotros los encargados de verificar que estan kevantados y funcionando 
# correctamnete ya que tienen posibilidades de caida yk8s no se ocupa si no los metemos en 
# deployments o replicasets  

#
# REPLICA SETS
#

# uno de loas mecanismos para que k8s se ocupe de nuestros pods es meterlo dentro de un replica set 
# se ocupara de que siempre este en el desired state marcado en el manifiesto del controller
# podemos ver toda la referncia del api del replicaset en la pagina de kubernmetes.io

# no es necesario escribir un manifiesto yaml para pod y para replicaset , en el replicaset podemos incluir 
# tanto el pod como el replicaset

# ya que es un unico manifiesto para los dos , el del pod va embebido dentro del replicaset como un template

apiVersion: apps/v1                                                          
kind: ReplicaSet                                                             
metadata:                                                                    
  name: webapp                                                               
spec:                                                                        
  replicas: 2  
  selector:
    matchLabels:
      app: webapp                                                              
  template:                                                                  
    metadata:                                                                
      labels:                                                                
        app: webapp                                                          
    spec:                                                                    
      containers:                                                            
        - name: webapp                                                       
          image: richardchesterwood/k8s-fleetman-webapp-angular:release0-5   
                                                                             

#
# DEPLOYMENTS
#
# el deplyment es como un relicaset pero con rolling updates incluido , es decir el manifesto 
# para el replica set nos vale solo con cambiar el tipo, tiene mas funcionalidaees añadidas 

apiVersion: apps/v1                                                          
kind: Deployment                                                             
metadata:                                                                    
  name: webapp                                                               
spec:                                                                        
  selector:
    matchLabels:
      app: webapp                                                              
  replicas: 2  
  template:                                                                  
    metadata:                                                                
      labels:                                                                
        app: webapp                                                          
    spec:                                                                    
      containers:                                                            
      - name: webapp                                                       
        image: richardchesterwood/k8s-fleetman-webapp-angular:release0   

# en este caso no hay que jugar con los tags como con el replica set , el deployment se ocupa de hacer un 
# rolling update, solo con cambiar la imagen lo que hace es crear un nuevo replicaset con la nueva veriosn 
# de la imagen y en cuanto esten los pods ready , pone 0 replicas el replicaset anterior de forma 
# que es servicio no se cae y lo da desde el nuevo con la nueva version
#en algunos casos es necesario daral go de tiempo para la paraday aranque con 
#  minReadySeconds: 30

apiVersion: apps/v1                                                          
kind: Deployment                                                             
metadata:                                                                    
  name: webapp                                                               
spec:
  minReadySeconds: 30                                                                        
  selector:
    matchLabels:
      app: webapp                                                              
  replicas: 2  
  template:                                                                  
    metadata:                                                                
      labels:                                                                
        app: webapp                                                          
    spec:                                                                    
      containers:                                                            
      - name: webapp                                                       
        image: richardchesterwood/k8s-fleetman-webapp-angular:release0-5   

#
# namespaces
#
# es la forma de particionar los recursos en kubernetes , en openshift
# son los projectos. Cad namespace es un area estanca dentro del cluster

oc get namespaces (ns)
oc get pods -n kube-system

# tanto kube-system como kube-public son usados por ocp de forma interna
# vamos a trabajar con networking entre pods con un ejemplo
# de una mysql en un pod y en otro la app
# para ello vamos a crear 2 manifiestos el del pod y del servicio database
# se vana a comunicar internbamente con ClusteriP y port 3306
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
  type: ClusterIP


