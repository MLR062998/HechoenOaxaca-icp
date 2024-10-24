import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Random "mo:base/Random";
import Time "mo:base/Time";  // Agregamos esta línea

// Actor principal para gestionar productos, artesanos y pedidos
actor HechoenOaxacaBackend {

    // Definición del tipo Producto
    type Producto = {
        id: Principal;
        nombre: Text;
        precio: Float;
        descripcion: Text;
        artesano: Text;
        tipo: Text;
        imagen: ?Blob;
    };

    // Definición del tipo Artesano
    type Artesano = {
        id: Principal;
        nombre: Text;
        especialidad: Text;
        email: Text;
    };

    // Definición del tipo Pedido de Artesano
    type Pedido = {
        id: Principal;
        artesanoId: Principal;
        productos: [Producto];
        total: Float;
  // Tipo Time para la fecha
    };

    // Definición del tipo AplicationError
    type AplicationError = {
        #ProductoNoExiste: Text;
        #ArtesanoNoExiste: Text;
        #PedidoNoExiste: Text;
    };

    // Tabla de productos usando HashMap
    var productos_table: HashMap.HashMap<Principal, Producto> = 
        HashMap.HashMap<Principal, Producto>(10, Principal.equal, Principal.hash);

    // Tabla de artesanos usando HashMap
    var artesanos_table: HashMap.HashMap<Principal, Artesano> = 
        HashMap.HashMap<Principal, Artesano>(10, Principal.equal, Principal.hash);

    // Tabla de pedidos usando HashMap
    var pedidos_table: HashMap.HashMap<Principal, Pedido> = 
        HashMap.HashMap<Principal, Pedido>(10, Principal.equal, Principal.hash);

    // Función para generar un ID aleatorio
    private func generateId(): async Principal {
        let randomBlob = await Random.blob();
        let randomBytes = Array.subArray(Blob.toArray(randomBlob), 0, 29);
        return Principal.fromBlob(Blob.fromArray(randomBytes));
    };

    // Crear un producto
    public shared({caller = _ }) func createProducto(
        nombre: Text,
        precio: Float,
        descripcion: Text,
        artesano: Text,
        tipo: Text
    ): async Producto {
        let id = await generateId();
        let producto: Producto = {
            id = id;
            nombre = nombre;
            precio = precio;
            descripcion = descripcion;
            artesano = artesano;
            tipo = tipo;
            imagen = null;
        };
        productos_table.put(id, producto);
        return producto;
    };

    // Crear un artesano
    public shared({caller = _ }) func createArtesano(
        nombre: Text,
        especialidad: Text,
        email: Text
    ): async Artesano {
        let id = await generateId();
        let artesano: Artesano = {
            id = id;
            nombre = nombre;
            especialidad = especialidad;
            email = email;
        };
        artesanos_table.put(id, artesano);
        return artesano;
    };

    // Crear un pedido
    public shared({caller = _ }) func createPedido(
        artesanoId: Principal,
        productos: [Producto],
        total: Float
    ): async Result.Result<Pedido, AplicationError> {
        switch (artesanos_table.get(artesanoId)) {
            case (?artesano) {
                let id = await generateId();
                let pedido: Pedido = {
                    id = id;
                    artesanoId = artesanoId;
                    productos = productos;
                    total = total;
                    fecha = Time.now();
                };
                pedidos_table.put(id, pedido);
                return #ok(pedido);
            };
            case null {
                return #err(#ArtesanoNoExiste(Principal.toText(artesanoId)));
            };
        }
    };

    // Leer todos los productos
    public query func readProductos(): async [Producto] {
        return Iter.toArray(productos_table.vals());
    };

    // Leer todos los artesanos
    public query func readArtesanos(): async [Artesano] {
        return Iter.toArray(artesanos_table.vals());
    };

    // Leer todos los pedidos
    public query func readPedidos(): async [Pedido] {
        return Iter.toArray(pedidos_table.vals());
    };

    // Leer un producto por ID
    public query func readProductoById(id: Principal): async ?Producto {
        return productos_table.get(id);
    };

    // Leer un artesano por ID
    public query func readArtesanoById(id: Principal): async ?Artesano {
        return artesanos_table.get(id);
    };

    // Leer un pedido por ID
    public query func readPedidoById(id: Principal): async ?Pedido {
        return pedidos_table.get(id);
    };

    // Eliminar un producto por ID
    public shared({caller = _ }) func deleteProducto(
        id: Principal
    ): async Result.Result<Producto, AplicationError> {
        switch (productos_table.remove(id)) {
            case (?producto) { return #ok(producto); };
            case null { return #err(#ProductoNoExiste(Principal.toText(id))); };
        }
    };

    // Eliminar un artesano por ID
    public shared({caller = _ }) func deleteArtesano(
        id: Principal
    ): async Result.Result<Artesano, AplicationError> {
        switch (artesanos_table.remove(id)) {
            case (?artesano) { return #ok(artesano); };
            case null { return #err(#ArtesanoNoExiste(Principal.toText(id))); };
        }
    };

    // Eliminar un pedido por ID
    public shared({caller = _ }) func deletePedido(
        id: Principal
    ): async Result.Result<Pedido, AplicationError> {
        switch (pedidos_table.remove(id)) {
            case (?pedido) { return #ok(pedido); };
            case null { return #err(#PedidoNoExiste(Principal.toText(id))); };
        }
    };
}
