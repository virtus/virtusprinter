#encoding: UTF-8
require "httparty"

class VirtusPrinter
  include HTTParty
  attr_reader :error

  def initialize(remote = true)
    config = YAML::load_file("./virtusprinter.yml")
    @vp_domain = config['virtusprinter']['domain']
    @vp_subdomain = config['virtusprinter']['subdomain']
    @vp_email = config['virtusprinter']['email']
    @vp_password = config['virtusprinter']['password']
    @vp_local = config['virtusprinter']['local']
    if @vp_local
      self.class.base_uri "http://#{@vp_subdomain}.lvh.me:3000"
    else
      self.class.base_uri "http://#{@vp_subdomain}.#{@vp_domain}"
    end
    @auth = {:username => @vp_email, :password => @vp_password}
  end

  def post_label(printer_id, xml)
    response = self.class.post "/printers/#{printer_id}/labels.xml", :basic_auth => @auth, :headers => { "Content-Type" => "application/xml"}, :body => xml
    case response.code
    when 201
      return true
    when 404
      @error = "No encontré la impresora #{printer_id}"
      return false
    when 406
      @error = "No existe el formato"
      return false
    when 500
      @error = "Error en el servidor"
      return false
    else
      @error = "Error desconocido"
      return false
    end
  end

  def get_labels(computer_id)
    response = self.class.get "/computers/#{computer_id}/labels.xml", :basic_auth => @auth
    case response.code
    when 200
      return true, response.body
    when 401
      @error = "Error en usuario o contraseña"
      return false
    when 404
      @error = "No encontré la computadora #{computer_id}"
      return false
    when 500
      @error = "Error en el servidor"
      return false
    else
      @error = "Error desconocido #{response.code}"
      return false
    end
  end

  def update_label(label_id, status, error = '')
    response = self.class.put "/labels/#{label_id}.xml", :basic_auth => @auth, :body => {:status => status, :error => error}
    case response.code
    when 200
      return true
    when 400
      @error = "Parámetros incorrectos"
      return false
    when 404
      @error = "No encontré la etiqueta"
      return false
    when 401
      @error = "Error en usuario o contraseña"
      return false
    when 500
      @error = "Error en el servidor"
      return false
    else
      @error = "Error desconocido #{response.code}"
      return false
    end
  end

  def test_template(template_id, port)
    response = self.class.get "/templates/#{template_id}/test.xml", :basic_auth => @auth, :query => {"port" => port}
    case response.code
    when 200
      return true, response.body
    when 401
      @error = "Error en usuario o contraseña"
      return false
    when 404
      @error = "No encontré el formato #{template_id}"
      return false
    when 500
      @error = "Error en el servidor"
      return false
    else
      @error = "Error desconocido #{response.code}"
      return false
    end
  end
end
