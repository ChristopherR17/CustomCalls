const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description": "Dibuixa un cercle. Permet x, y, radius, fillColor, strokeColor i strokeWidth. Els colors poden ser noms com red, blue, verde, blau o codis hex com #FF0000.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"},
          "fillColor": {"type": "string"},
          "strokeColor": {"type": "string"},
          "strokeWidth": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description": "Dibuixa una línia entre dos punts. Permet startX, startY, endX, endY, color i strokeWidth.",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {"type": "number"},
          "startY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "color": {"type": "string"},
          "strokeWidth": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description": "Dibuixa un rectangle. Permet topLeftX, topLeftY, bottomRightX, bottomRightY o width i height. També fillColor, strokeColor, strokeWidth, gradientStartColor i gradientEndColor.",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {"type": "number"},
          "topLeftY": {"type": "number"},
          "bottomRightX": {"type": "number"},
          "bottomRightY": {"type": "number"},
          "width": {"type": "number"},
          "height": {"type": "number"},
          "fillColor": {"type": "string"},
          "strokeColor": {"type": "string"},
          "strokeWidth": {"type": "number"},
          "gradientStartColor": {"type": "string"},
          "gradientEndColor": {"type": "string"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_square",
      "description": "Dibuixa un quadrat. Permet x, y, size, fillColor, strokeColor, strokeWidth, gradientStartColor i gradientEndColor.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "size": {"type": "number"},
          "fillColor": {"type": "string"},
          "strokeColor": {"type": "string"},
          "strokeWidth": {"type": "number"},
          "gradientStartColor": {"type": "string"},
          "gradientEndColor": {"type": "string"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description": "Dibuixa un text. Permet text, x, y, color, fontSize, bold i fontFamily.",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "color": {"type": "string"},
          "fontSize": {"type": "number"},
          "bold": {"type": "boolean"},
          "fontFamily": {"type": "string"}
        },
        "required": ["text"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "select_shape",
      "description": "Selecciona una figura pel seu id. Si no es passa id, pot seleccionar la darrera figura creada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "last": {"type": "boolean"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "delete_shape",
      "description": "Esborra una figura pel seu id. Si no es passa id, esborra la figura seleccionada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "update_shape",
      "description": "Canvia propietats d'una figura existent. Permet id i propietats com color, fillColor, strokeColor, strokeWidth, x, y, radius, width, height, text, fontSize, bold, etc. Si no es passa id, modifica la seleccionada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "color": {"type": "string"},
          "fillColor": {"type": "string"},
          "strokeColor": {"type": "string"},
          "strokeWidth": {"type": "number"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"},
          "width": {"type": "number"},
          "height": {"type": "number"},
          "text": {"type": "string"},
          "fontSize": {"type": "number"},
          "bold": {"type": "boolean"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "clear_canvas",
      "description": "Esborra tot el dibuix.",
      "parameters": {
        "type": "object",
        "properties": {}
      }
    }
  }
];
