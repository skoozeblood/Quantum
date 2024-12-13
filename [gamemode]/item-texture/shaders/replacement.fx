texture theTexture;

technique TexReplace
{
    pass P0
    {
        Texture[0] = theTexture;
    }
}