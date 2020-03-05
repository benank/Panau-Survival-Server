class 'cInventoryUIStyle'

function cInventoryUIStyle:__init()


    self.background_alpha = 140
    self.default_inv_size = 1000 -- 800 px wide for the entire inventory
    self.colors = 
    {
        default = 
        {
            background = Color(0, 0, 0, self.background_alpha),
            border = Color(255, 0, 0, 0),
            text = Color(220, 220, 220, 255),
            text_hover = Color(255, 255, 255, 255)
        },
        dropping = 
        {
            background = Color(100, 0, 0, self.background_alpha),
            border = Color(255, 0, 0, 255),
            text = Color(220, 0, 0, 255),
            text_hover = Color(255, 0, 0, 255)
        },
        hover = 
        {
            background = Color(50, 50, 50, self.background_alpha),
            border = Color(255, 255, 255, 200),
            text = Color(220, 220, 220, 255),
            text_hover = Color(255, 255, 255, 255)
        }
    }

    self.category_title_colors = {Normal = Color.White, Full = Color.Red}
    self.border_size = 2


end

InventoryUIStyle = cInventoryUIStyle()